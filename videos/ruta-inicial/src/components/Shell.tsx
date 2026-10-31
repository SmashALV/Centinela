import type {ReactNode} from "react";
import {Easing, interpolate, useCurrentFrame, useVideoConfig} from "remotion";
import type {Cue} from "../data";
import {background, colors, font} from "../theme";

type ShellProps = {
  readonly section: string;
  readonly title: string;
  readonly accent: string;
  readonly captions: Cue[];
  readonly step?: {index: number; total: number};
  readonly children: ReactNode;
  readonly label?: string;
};

const ease = Easing.bezier(0.2, 0.75, 0.25, 1);

export const Backdrop = ({children}: {readonly children: ReactNode}) => (
  <div style={{position: "absolute", inset: 0, overflow: "hidden", background, color: colors.ink, fontFamily: font}}>
    <div
      style={{
        position: "absolute",
        inset: 0,
        opacity: 0.35,
        backgroundImage: "radial-gradient(rgba(138,95,176,.18) 2px, transparent 2px)",
        backgroundSize: "44px 44px",
      }}
    />
    {children}
  </div>
);

export const Shell = ({section, title, accent, captions, step, children, label = "CENTINELA 2.0 · RUTA INICIAL"}: ShellProps) => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames} = useVideoConfig();
  const enter = interpolate(frame, [0, 14], [0, 1], {extrapolateRight: "clamp", easing: ease});
  const leave = interpolate(frame, [durationInFrames - 10, durationInFrames], [1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"});
  const active = [...captions].reverse().find((cue) => frame >= cue.from * fps) ?? captions[0];
  const captionIn = active
    ? interpolate(frame, [active.from * fps, active.from * fps + 8], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease})
    : 1;

  return (
    <Backdrop>
      <div style={{position: "absolute", inset: 0, opacity: leave}}>
        <div style={{position: "absolute", left: 90, right: 90, top: 44, display: "flex", alignItems: "center", gap: 16, opacity: enter}}>
          <div style={{width: 14, height: 14, borderRadius: 99, background: accent, boxShadow: `0 0 18px ${accent}`}} />
          <div style={{fontSize: 24, letterSpacing: 4, fontWeight: 700, color: accent}}>{section.toUpperCase()}</div>
          <div style={{flex: 1, height: 2, background: colors.line}} />
          {step ? (
            <div style={{display: "flex", gap: 7}}>
              {Array.from({length: step.total}, (_, i) => (
                <div key={i} style={{width: i === step.index ? 34 : 12, height: 12, borderRadius: 99, background: i <= step.index ? accent : "rgba(138,95,176,.2)"}} />
              ))}
            </div>
          ) : null}
          <div style={{fontSize: 22, letterSpacing: 3, color: colors.muted, fontWeight: 600}}>{label}</div>
        </div>
        <div
          style={{
            position: "absolute",
            left: 90,
            top: 92,
            fontSize: 64,
            fontWeight: 780,
            letterSpacing: -1.5,
            opacity: enter,
            translate: `0px ${(1 - enter) * 18}px`,
          }}
        >
          {title}
        </div>
        {children}
        <div
          style={{
            position: "absolute",
            left: 90,
            right: 90,
            bottom: 34,
            minHeight: 100,
            boxSizing: "border-box",
            display: "flex",
            alignItems: "center",
            gap: 22,
            padding: "18px 30px",
            borderRadius: 22,
            background: "rgba(59,42,74,.92)",
            boxShadow: "0 18px 50px rgba(59,42,74,.25)",
            borderLeft: `8px solid ${accent}`,
            opacity: enter * captionIn,
          }}
        >
          <div style={{fontSize: 38, lineHeight: 1.25, fontWeight: 560, color: "#fff7fd"}}>{active?.text}</div>
        </div>
      </div>
    </Backdrop>
  );
};
