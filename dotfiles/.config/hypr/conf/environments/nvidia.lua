-- NVIDIA is the only GPU (chosen by catastrophic-hypr-tune). On laptops with a second GPU
-- these are not set: they would push every OpenGL and video app onto the NVIDIA card.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
