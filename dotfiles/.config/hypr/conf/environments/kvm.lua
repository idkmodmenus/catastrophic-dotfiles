-- Virtual machine (chosen by catastrophic-hypr-tune): software rendering is allowed, and
-- the hardware cursor is turned off because virtual GPUs often cannot draw it.
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")
hl.config({ cursor = { no_hardware_cursors = true } })
