import {Easing, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from "remotion";
import type {Shot} from "../data";

type GameShotsProps = {
  readonly shots: Shot[];
  readonly left: number;
  readonly top: number;
  readonly width: number;
  readonly accent: string;
};

// Las capturas del juego son 1152×672; se muestran con fundido cruzado y un acercamiento lento.
export const GameShots = ({shots, left, top, width, accent}: GameShotsProps) => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames} = useVideoConfig();
  const height = Math.round((width * 672) / 1152);
  const enter = spring({frame: frame - 4, fps, config: {damping: 20, stiffness: 110}});

  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        width,
        height,
        borderRadius: 24,
        overflow: "hidden",
        background: "#2b2035",
        boxShadow: `0 28px 70px rgba(59,42,74,.28), 0 0 0 6px #fff, 0 0 0 9px ${accent}55`,
        opacity: enter,
        scale: String(0.94 + enter * 0.06),
      }}
    >
      {shots.map((shot, index) => {
        const start = shot.from * fps;
        const end = index + 1 < shots.length ? shots[index + 1].from * fps : durationInFrames;
        if (frame < start - 1 || frame > end + 12) return null;
        const opacity = index === 0 ? 1 : interpolate(frame, [start, start + 12], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.out(Easing.cubic)});
        const zoom = interpolate(frame, [start, end + 12], [1, 1.045], {extrapolateLeft: "clamp", extrapolateRight: "clamp"});
        return (
          <Img
            key={shot.src}
            src={staticFile(shot.src)}
            style={{position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", opacity, scale: String(zoom), transformOrigin: index % 2 ? "30% 40%" : "70% 60%"}}
          />
        );
      })}
    </div>
  );
};
