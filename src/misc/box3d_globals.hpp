#pragma once

// Extension-wide lifecycle hooks. Box3D itself has no global init/shutdown call in its
// public API (worlds are independent allocations), so these are currently no-ops, but are
// kept as a single choke point in case future Box3D versions add one, and to mirror
// godot-jolt's structure.

void box3d_initialize();

void box3d_deinitialize();
