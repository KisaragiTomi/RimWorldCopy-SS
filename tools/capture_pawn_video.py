"""
Capture a short video clip following a specific pawn.
Centers camera on pawn position with 5-cell radius view, captures 60 frames,
and encodes to MP4 via FFmpeg.

Usage:
  python tools/capture_pawn_video.py [pawn_index] [output]
  python tools/capture_pawn_video.py 0 screenshots/pawn0.mp4
  python tools/capture_pawn_video.py --name "Ozzy" screenshots/ozzy.mp4
"""
import socket, json, sys, base64, pathlib, subprocess, time, shutil, argparse

HOST, PORT = "127.0.0.1", 9090
CELL_SIZE = 16
CELL_RADIUS = 5
FRAME_COUNT = 60
FRAME_INTERVAL = 0.05  # 50ms between frames -> ~20fps capture rate


def send_cmd(cmd_dict, timeout=15):
    s = socket.create_connection((HOST, PORT), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk:
            break
        buf += chunk
        if b"\n" in buf:
            break
    s.close()
    return json.loads(buf.split(b"\n")[0])


def get_pawn_pos(pawn_index=0, pawn_name=None):
    if pawn_name:
        code = (
            f'for p in PawnManager.pawns:\n'
            f'\tif p.pawn_name == "{pawn_name}":\n'
            f'\t\treturn {{"name": p.pawn_name, "x": p.grid_pos.x, "y": p.grid_pos.y, "id": p.pawn_id}}\n'
            f'return {{"error": "pawn not found"}}'
        )
    else:
        code = (
            f'var p = PawnManager.pawns[{pawn_index}]\n'
            f'return {{"name": p.pawn_name, "x": p.grid_pos.x, "y": p.grid_pos.y, "id": p.pawn_id}}'
        )
    result = send_cmd({"command": "eval", "params": {"code": code}})
    data = result.get("result", result)
    if isinstance(data, str):
        data = json.loads(data)
    return data


def get_viewport_size():
    result = send_cmd({"command": "eval", "params": {
        "code": 'var s = get_viewport().get_visible_rect().size\nreturn {"w": s.x, "h": s.y}'
    }})
    data = result.get("result", result)
    if isinstance(data, str):
        data = json.loads(data)
    return data.get("w", 1152), data.get("h", 648)


def center_camera_on_pawn(px, py, vw, vh):
    view_cells = CELL_RADIUS * 2 + 1  # 11 cells
    zoom_level = vw / (view_cells * CELL_SIZE)
    cam_x = px * CELL_SIZE + CELL_SIZE * 0.5
    cam_y = py * CELL_SIZE + CELL_SIZE * 0.5
    send_cmd({"command": "set_camera", "params": {
        "position": {"x": cam_x, "y": cam_y},
        "zoom": {"x": zoom_level, "y": zoom_level}
    }})
    return zoom_level


def capture_frame(frame_dir, frame_idx):
    result = send_cmd({"command": "screenshot"}, timeout=15)
    img_b64 = result.get("data", "")
    if not img_b64:
        return False
    frame_path = frame_dir / f"frame_{frame_idx:04d}.png"
    frame_path.write_bytes(base64.b64decode(img_b64))
    return True


def frames_to_video(frame_dir, output_path, fps=20):
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        print("ERROR: ffmpeg not found in PATH")
        return False
    cmd = [
        ffmpeg, "-y",
        "-framerate", str(fps),
        "-i", str(frame_dir / "frame_%04d.png"),
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-crf", "18",
        str(output_path)
    ]
    subprocess.run(cmd, capture_output=True)
    return output_path.exists()


def main():
    parser = argparse.ArgumentParser(description="Capture video following a pawn")
    parser.add_argument("pawn", nargs="?", default="0", help="Pawn index or --name")
    parser.add_argument("output", nargs="?", default="screenshots/pawn_video.mp4")
    parser.add_argument("--name", type=str, help="Pawn name to follow")
    parser.add_argument("--frames", type=int, default=FRAME_COUNT)
    parser.add_argument("--radius", type=int, default=CELL_RADIUS)
    parser.add_argument("--fps", type=int, default=20)
    args = parser.parse_args()

    global CELL_RADIUS, FRAME_COUNT
    CELL_RADIUS = args.radius
    FRAME_COUNT = args.frames

    output = pathlib.Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    frame_dir = pathlib.Path("screenshots/_frames")
    if frame_dir.exists():
        shutil.rmtree(frame_dir)
    frame_dir.mkdir(parents=True)

    pawn_name = args.name
    pawn_index = int(args.pawn) if not pawn_name else 0

    pawn_info = get_pawn_pos(pawn_index, pawn_name)
    if "error" in pawn_info:
        print(f"ERROR: {pawn_info['error']}")
        return

    print(f"Following pawn: {pawn_info.get('name', '?')} at ({pawn_info['x']}, {pawn_info['y']})")

    vw, vh = get_viewport_size()
    print(f"Viewport: {vw}x{vh}")

    saved_cam = send_cmd({"command": "get_camera"})

    print(f"Capturing {args.frames} frames (radius={args.radius} cells)...")
    for i in range(args.frames):
        pawn_info = get_pawn_pos(pawn_index, pawn_name)
        if "error" in pawn_info:
            print(f"  Frame {i}: pawn lost, stopping")
            break
        center_camera_on_pawn(pawn_info["x"], pawn_info["y"], vw, vh)
        time.sleep(0.02)
        ok = capture_frame(frame_dir, i)
        if not ok:
            print(f"  Frame {i}: capture failed")
            break
        if (i + 1) % 10 == 0:
            print(f"  {i+1}/{args.frames} frames captured")
        time.sleep(FRAME_INTERVAL)

    if saved_cam.get("camera_2d"):
        cam = saved_cam["camera_2d"]
        send_cmd({"command": "set_camera", "params": {
            "position": cam["position"],
            "zoom": cam["zoom"]
        }})

    print("Encoding video...")
    if frames_to_video(frame_dir, output, args.fps):
        print(f"Video saved: {output}")
        print(f"  Frames: {args.frames}, FPS: {args.fps}, Duration: {args.frames/args.fps:.1f}s")
    else:
        print(f"FFmpeg encoding failed. Raw frames in: {frame_dir}")

    shutil.rmtree(frame_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
