# Claude:
# --multi-clients
#     Lets more than one ParaView client connect to this pvserver at the
#     same time, all sharing the same session (collaboration mode). Each
#     client sees the same pipeline and data. Without it, pvserver accepts
#     one client and shuts down when that client disconnects.
#
# --force-offscreen-rendering
#     Renders into offscreen buffers instead of opening an on-screen window
#     on the server. Needed on headless compute nodes with no display, and
#     it avoids stray render windows popping up on the remote machine.
#
# --opengl-window-backend=EGL
#     Picks the OpenGL context backend at runtime (ParaView 5.12+ builds
#     ship GLX, EGL and OSMesa). EGL renders on the GPU through the NVIDIA
#     driver without needing an X server, so you get hardware-accelerated
#     rendering on a headless node. The alternatives are GLX, which needs
#     an X display, and OSMesa, which renders in software on the CPU and
#     is much slower.

./pvserver --multi-clients --force-offscreen-rendering --opengl-window-backend=EGL
