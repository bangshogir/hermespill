//! Hermes Mission Control data: agent fleet / task status pushed from the
//! Hermes side (or any script) over the local `/hermes` webhook.
//!
//! Mirrors the shape of `UsageSnapshot`: a single shared snapshot, a revision
//! counter the render loop watches, and a JSON payload the webhook fills in.

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use parking_lot::RwLock;
use serde::Deserialize;

/// One agent/task row shown in the Mission Control slide.
#[derive(Debug, Clone, Default, Deserialize)]
pub struct HermesTask {
    /// Short label, e.g. "tokenharbor-farm" or a session name.
    #[serde(default)]
    pub name: String,
    /// One of: running | idle | done | error | queued (free-form, drawn as-is).
    #[serde(default)]
    pub state: String,
    /// Optional 0..=100 progress for a bar.
    pub progress: Option<f32>,
}

/// Latest Mission Control snapshot, reported over the `/hermes` webhook.
#[derive(Debug, Clone, Default)]
pub struct HermesSnapshot {
    /// Headline, e.g. "3 agents live" or a custom line.
    pub headline: Option<String>,
    /// Active task/agent rows (kept small: first few only).
    pub tasks: Vec<HermesTask>,
    /// Today's spend, if reported.
    pub cost_usd: Option<f64>,
    /// Active cron job count, if reported.
    pub cron_active: Option<u32>,
    /// When this snapshot was last updated, so a stale slide can say so.
    pub updated_at_secs: u64,
}

/// JSON payload received over the local `/hermes` webhook endpoint.
#[derive(Debug, Deserialize)]
pub struct HermesPayload {
    pub headline: Option<String>,
    #[serde(default)]
    pub tasks: Vec<HermesTask>,
    pub cost_usd: Option<f64>,
    pub cron_active: Option<u32>,
}

/// How many task rows the slide will ever draw.
pub const MAX_TASKS: usize = 6;

static HERMES_STORE: RwLock<Option<Arc<RwLock<HermesSnapshot>>>> = RwLock::new(None);
static HERMES_REVISION: AtomicU64 = AtomicU64::new(0);

/// Bumped on every `/hermes` post, so the notch repaints when one lands.
pub fn revision() -> u64 {
    HERMES_REVISION.load(Ordering::Acquire)
}

pub fn store() -> Arc<RwLock<HermesSnapshot>> {
    let read = HERMES_STORE.read();
    if let Some(store) = read.as_ref() {
        return Arc::clone(store);
    }
    drop(read);
    let mut write = HERMES_STORE.write();
    if let Some(store) = write.as_ref() {
        return Arc::clone(store);
    }
    let store = Arc::new(RwLock::new(HermesSnapshot::default()));
    *write = Some(Arc::clone(&store));
    store
}

/// Apply a `/hermes` payload into the shared snapshot and bump the revision.
pub fn ingest(payload: HermesPayload) {
    let epoch = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let mut tasks = payload.tasks;
    if tasks.len() > MAX_TASKS {
        tasks.truncate(MAX_TASKS);
    }
    let store = store();
    *store.write() = HermesSnapshot {
        headline: payload.headline.map(|s| s.trim().to_string()).filter(|s| !s.is_empty()),
        tasks,
        cost_usd: payload.cost_usd,
        cron_active: payload.cron_active,
        updated_at_secs: epoch,
    };
    HERMES_REVISION.fetch_add(1, Ordering::AcqRel);
}

/// True when at least one reported task is running (drives the collapsed hint).
pub fn any_running() -> bool {
    store()
        .read()
        .tasks
        .iter()
        .any(|t| t.state.eq_ignore_ascii_case("running"))
}

/// How long ago the last update landed, phrased for the slide footer.
pub fn updated_ago() -> Option<String> {
    let snap = store();
    let s = snap.read();
    if s.updated_at_secs == 0 {
        return None;
    }
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let d = now.saturating_sub(s.updated_at_secs);
    Some(if d < 60 {
        format!("updated {}s ago", d)
    } else if d < 3600 {
        format!("updated {}m ago", d / 60)
    } else {
        format!("updated {}h ago", d / 3600)
    })
}
