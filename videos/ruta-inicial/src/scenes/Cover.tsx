import {Easing, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from "remotion";
import {Backdrop} from "../components/Shell";
import {colors} from "../theme";

const cast = [
  {id: "camila", name: "Camila"},
  {id: "bruno", name: "Bruno"},
  {id: "sofi", name: "Sofi"},
  {id: "mateo", name: "Mateo"},
  {id: "sebas", name: "Sebas"},
];

export const Cover = () => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames} = useVideoConfig();
  const title = spring({frame: frame - 6, fps, config: {damping: 18, stiffness: 90}});
  const leave = interpolate(frame, [durationInFrames - 10, durationInFrames], [1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"});
  const drift = interpolate(frame, [0, durationInFrames], [1.04, 1.1]);

  return (
    <Backdrop>
      <div style={{position: "absolute", inset: 0, opacity: leave}}>
        <Img src={staticFile("personajes/courtyard.png")} style={{position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", opacity: 0.38, scale: String(drift), filter: "blur(3px) saturate(1.1)"}} />
        <div style={{position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(247,239,251,.92) 0%, rgba(247,239,251,.55) 45%, rgba(251,238,244,.2) 100%)"}} />
        <div style={{position: "absolute", left: 0, right: 0, top: 110, textAlign: "center", opacity: title, translate: `0px ${(1 - title) * 30}px`}}>
          <div style={{fontSize: 30, letterSpacing: 8, fontWeight: 700, color: colors.pink}}>GUÍA DE JUGABILIDAD</div>
          <div style={{fontSize: 132, fontWeight: 820, letterSpacing: -4, marginTop: 6}}>Centinela 2.0</div>
          <div style={{fontSize: 46, fontWeight: 600, color: colors.soft, marginTop: 4}}>Ruta inicial · Día 0</div>
        </div>
        <div style={{position: "absolute", left: 0, right: 0, bottom: -70, display: "flex", justifyContent: "center", alignItems: "flex-end", gap: 0}}>
          {cast.map((person, i) => {
            const rise = spring({frame: frame - 14 - Math.abs(i - 2) * 5, fps, config: {damping: 16, stiffness: 90}});
            const main = person.id === "sofi";
            return (
              <div key={person.id} style={{position: "relative", width: main ? 400 : 340, marginLeft: i ? -60 : 0, zIndex: main ? 2 : 1, opacity: rise, translate: `0px ${(1 - rise) * 120}px`}}>
                <Img src={staticFile(`personajes/${person.id}_v4.png`)} style={{width: "100%", filter: main ? "drop-shadow(0 18px 30px rgba(59,42,74,.35))" : "drop-shadow(0 12px 22px rgba(59,42,74,.25)) saturate(.92)"}} />
                <div
                  style={{
                    position: "absolute",
                    left: "50%",
                    top: main ? -34 : -10,
                    translate: "-50% 0",
                    padding: "6px 20px",
                    borderRadius: 99,
                    background: main ? colors.pink : "rgba(59,42,74,.85)",
                    color: "#fff",
                    fontSize: 26,
                    fontWeight: 700,
                    opacity: interpolate(frame, [40, 52], [0, 1], {extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.out(Easing.cubic)}),
                  }}
                >
                  {person.name}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </Backdrop>
  );
};
