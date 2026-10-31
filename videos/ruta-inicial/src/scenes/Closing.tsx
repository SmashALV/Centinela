import {interpolate, spring, useCurrentFrame, useVideoConfig} from "remotion";
import {GameShots} from "../components/GameShots";
import {Shell} from "../components/Shell";
import {colors} from "../theme";

const steps = [
  {day: "Día 0", text: "Conocer al grupo y la rutina", color: "#8a5fb0"},
  {day: "Día 1", text: "Mateo presenta a Kairo en Discord", color: "#d9679b"},
  {day: "Días 2–3", text: "Tres rutas según la primera decisión", color: "#3fa79b"},
  {day: "Día 4", text: "Buscar apoyo · Poner un límite · Decisión pendiente", color: "#d98b3a"},
];

export const Closing = () => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames} = useVideoConfig();
  const thanks = interpolate(frame, [durationInFrames - 3 * fps, durationInFrames - 3 * fps + 14], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp"});

  return (
    <Shell
      section="Cierre"
      title="Lo que viene después"
      accent={colors.pink}
      captions={[
        {from: 0, text: "Así termina la ruta inicial: el grupo, la rutina, las decisiones y la partida."},
        {from: 4.5, text: "Desde el Día 1, Mateo presenta a Kairo, alguien que conoció jugando en línea."},
        {from: 8.5, text: "Las decisiones de Sofi abren tres rutas y llevan a uno de tres finales. ¡Gracias por ver!"},
      ]}
    >
      <GameShots shots={[{src: "capturas/37_dia1.png", from: 0}]} left={90} top={200} width={1000} accent={colors.pink} />
      <div style={{position: "absolute", left: 1150, top: 208, width: 680, display: "flex", flexDirection: "column", gap: 18}}>
        {steps.map((step, i) => {
          const show = spring({frame: frame - 12 - i * 22, fps, config: {damping: 18, stiffness: 100}});
          return (
            <div key={step.day} style={{display: "flex", gap: 20, alignItems: "stretch", opacity: Math.min(1, show), translate: `${(1 - show) * 40}px 0px`}}>
              <div style={{display: "flex", flexDirection: "column", alignItems: "center", width: 26}}>
                <div style={{width: 26, height: 26, borderRadius: 99, background: step.color, border: "5px solid #fff", boxShadow: `0 0 0 2px ${step.color}`}} />
                {i < steps.length - 1 ? <div style={{flex: 1, width: 4, background: `${step.color}55`, marginTop: 6}} /> : null}
              </div>
              <div style={{flex: 1, borderRadius: 20, padding: "16px 22px", background: colors.card, border: `2px solid ${step.color}44`, boxShadow: "0 10px 28px rgba(59,42,74,.08)"}}>
                <div style={{fontSize: 26, fontWeight: 800, color: step.color, letterSpacing: 1}}>{step.day.toUpperCase()}</div>
                <div style={{fontSize: 30, fontWeight: 600, lineHeight: 1.25, marginTop: 4}}>{step.text}</div>
              </div>
            </div>
          );
        })}
      </div>
      <div style={{position: "absolute", left: 90, top: 200, width: 1000, height: 583, borderRadius: 24, display: "grid", placeItems: "center", background: `rgba(59,42,74,${0.72 * thanks})`, opacity: thanks}}>
        <div style={{textAlign: "center", color: "#fff"}}>
          <div style={{fontSize: 84, fontWeight: 820}}>¡Gracias por ver!</div>
          <div style={{fontSize: 34, marginTop: 10, color: "#f6d6e8"}}>Centinela 2.0 · versión 0.40.0-preview</div>
        </div>
      </div>
    </Shell>
  );
};
