import {Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from "remotion";
import type {Side} from "../data";
import {colors} from "../theme";

type SidePanelProps = {
  readonly side: Side;
  readonly accent: string;
  readonly left: number;
  readonly top: number;
  readonly width: number;
};

const appear = (frame: number, fps: number, delay: number) => {
  const progress = spring({frame: frame - delay, fps, config: {damping: 18, stiffness: 110}});
  return {opacity: Math.min(1, progress), translate: `${(1 - progress) * 40}px 0px`};
};

const card = (accent: string, highlight = false) => ({
  borderRadius: 20,
  background: highlight ? `${accent}1f` : colors.card,
  border: `2px solid ${highlight ? accent : "rgba(138,95,176,.18)"}`,
  boxShadow: highlight ? `0 14px 36px ${accent}40` : "0 10px 28px rgba(59,42,74,.08)",
  boxSizing: "border-box" as const,
});

const dot = (accent: string) => ({width: 14, height: 14, flex: "0 0 auto", borderRadius: 99, background: accent});

const classes = [
  {name: "Atacante", color: "#d9679b", q: "Proyectil fuerte hacia el cursor"},
  {name: "Defensor", color: "#6b8fd6", q: "Escudo al aliado más cercano"},
  {name: "Soporte", color: "#3fa79b", q: "Mejora a los aliados cercanos 5 s"},
];

export const SidePanel = ({side, accent, left, top, width}: SidePanelProps) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const wrap = {position: "absolute" as const, left, top, width, display: "flex", flexDirection: "column" as const, gap: 16};

  const points = (items: string[], start: number) =>
    items.map((text, i) => (
      <div key={text} style={{...card(accent), ...appear(frame, fps, start + i * 7), display: "flex", alignItems: "center", gap: 18, padding: "18px 22px"}}>
        <div style={dot(accent)} />
        <div style={{fontSize: 30, lineHeight: 1.25, fontWeight: 560}}>{text}</div>
      </div>
    ));

  if (side.kind === "points") return <div style={wrap}>{points(side.items, 14)}</div>;

  if (side.kind === "keys") {
    return (
      <div style={wrap}>
        {side.items.map((item, i) => (
          <div key={item.key} style={{...card(accent), ...appear(frame, fps, 14 + i * 7), display: "flex", alignItems: "center", gap: 20, padding: "14px 20px"}}>
            <div style={{minWidth: 92, padding: "8px 14px", textAlign: "center", borderRadius: 12, background: "#fff", border: `2px solid ${accent}`, boxShadow: `0 5px 0 ${accent}`, fontSize: 26, fontWeight: 800, color: accent}}>
              {item.key}
            </div>
            <div style={{fontSize: 30, fontWeight: 600}}>{item.label}</div>
          </div>
        ))}
      </div>
    );
  }

  if (side.kind === "options") {
    const picked = frame >= side.pickFrom * fps;
    return (
      <div style={wrap}>
        <div style={{fontSize: 24, letterSpacing: 3, fontWeight: 700, color: colors.soft}}>RESPONDER COMO SOFI</div>
        {side.items.map((item, i) => {
          const chosen = picked && i === side.pick;
          const base = appear(frame, fps, 14 + i * 8);
          return (
            <div key={item.letter} style={{...card(accent, chosen), ...base, opacity: base.opacity * (picked && !chosen ? 0.45 : 1), display: "flex", gap: 18, alignItems: "center", padding: "18px 20px", scale: chosen ? "1.03" : "1"}}>
              <div style={{width: 54, height: 54, flex: "0 0 auto", display: "grid", placeItems: "center", borderRadius: 99, background: chosen ? accent : "#fff", color: chosen ? "#fff" : accent, border: `2px solid ${accent}`, fontSize: 28, fontWeight: 800}}>
                {item.letter}
              </div>
              <div style={{fontSize: 28, lineHeight: 1.25, fontWeight: 560}}>{item.text}</div>
            </div>
          );
        })}
        <div style={{fontSize: 26, color: colors.soft, lineHeight: 1.3, opacity: interpolate(frame, [side.pickFrom * fps, side.pickFrom * fps + 12], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp"})}}>
          En el Día 0 la respuesta no cambia la historia, pero cada amigo reacciona distinto.
        </div>
      </div>
    );
  }

  const switchFrame = side.switchAt * fps;
  if (frame < switchFrame) {
    const fade = interpolate(frame, [switchFrame - 8, switchFrame], [1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.in(Easing.cubic)});
    return (
      <div style={{...wrap, opacity: fade}}>
        {classes.map((item, i) => (
          <div key={item.name} style={{...card(item.color), ...appear(frame, fps, 14 + i * 8), padding: "18px 22px", borderLeft: `10px solid ${item.color}`}}>
            <div style={{fontSize: 32, fontWeight: 800, color: item.color}}>{item.name}</div>
            <div style={{fontSize: 27, marginTop: 4}}>
              <b>Q:</b> {item.q}
            </div>
          </div>
        ))}
      </div>
    );
  }
  return <div style={wrap}>{points(side.rules, switchFrame + 4)}</div>;
};
