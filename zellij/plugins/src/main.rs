//! tab-titler — a Zellij plugin that renames tabs by name.
//!
//! Receives pipe messages of the form "tab_name\tnew_title" and renames
//! the tab whose current name matches `tab_name` (after stripping any
//! status prefix like ⚙/⚡/⌁).  Does not touch focus.
//!
//! Usage from a terminal pane:
//!   printf '%s\t%s' "$ZELLIJ_TAB_NAME" "⚙ my-tab" \
//!     | zellij pipe --plugin file:~/.config/zellij/plugins/tab-titler.wasm \
//!                   --name set_tab_title

use std::collections::BTreeMap;
use zellij_tile::prelude::*;

#[derive(Default)]
struct TabTitler {
    /// tab position (0-based) → tab name, refreshed on every TabUpdate
    tab_names: Vec<(usize, String)>,
}

/// Strip leading status‐indicator prefixes (⚙ /⚡ /⌁ ) that we ourselves
/// prepend, so we can match against the bare base name.
fn strip_status_prefix(name: &str) -> &str {
    let trimmed = name.trim_start();
    for prefix in &["⚙ ", "⚡ ", "⌁ "] {
        if let Some(rest) = trimmed.strip_prefix(prefix) {
            return rest;
        }
    }
    trimmed
}

register_plugin!(TabTitler);

impl ZellijPlugin for TabTitler {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ReadApplicationState, // for TabUpdate subscription
            PermissionType::ChangeApplicationState, // for rename_tab
            PermissionType::ReadCliPipes,         // for unblock_cli_pipe_input
        ]);
        subscribe(&[EventType::TabUpdate]);
        set_selectable(false);
    }

    fn update(&mut self, event: Event) -> bool {
        if let Event::TabUpdate(tabs) = event {
            self.tab_names = tabs.iter().map(|t| (t.position, t.name.clone())).collect();
        }
        false
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        if let Some(payload) = &pipe_message.payload {
            if let Some((target_name, title)) = payload.split_once('\t') {
                let target = target_name.trim();
                // Find the tab whose base name (sans status prefix) matches.
                if let Some((pos, _)) = self
                    .tab_names
                    .iter()
                    .find(|(_, name)| strip_status_prefix(name) == target)
                {
                    rename_tab(*pos as u32 + 1, title.trim());
                }
            }
        }
        if let PipeSource::Cli(pipe_id) = &pipe_message.source {
            unblock_cli_pipe_input(pipe_id);
        }
        false
    }
}
