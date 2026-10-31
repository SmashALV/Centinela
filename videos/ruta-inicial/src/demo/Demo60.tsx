import type {ReactNode} from "react";
import {Audio, Composition, Easing, Img, Sequence, Series, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from "remotion";
import {GameShots} from "../components/GameShots";
import {Backdrop, Shell} from "../components/Shell";
import type {Cue, Shot} from "../data";
import {FPS, HEIGHT, WIDTH, colors} from "../theme";

// Demo de 60 s para la exposición: rutina → recreo → decisión → Discord y Arena → finales.
const LABEL = "CENTINELA 2.0 · DEMO 60 s";
const c = (name: string) => `capturas/${name}.png`;
const ease = Easing.bezier(0.2, 0.75, 0.25, 1);

const scenes = [
  {id: "portada", seconds: 5},
  {id: "rutina", seconds: 9},
  {id: "recreo", seconds: 11},
  {id: "decision", seconds: 11},
  {id: "arena", seconds: 9},
  {id: "finales", seconds: 10},
  {id: "cierre", seconds: 5},
] as const;

export const DEMO_FRAMES = scenes.reduce((sum, scene) => sum + scene.seconds, 0) * FPS;

const useAppear = (delay: number) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return spring({frame: frame - delay * fps, fps, config: {damping: 18, stiffness: 110}});
};

const Card = ({delay, children, accent, style}: {readonly delay: number; readonly children: ReactNode; readonly accent: string; readonly style?: React.CSSProperties}) => {
  const a = useAppear(delay);
  return (
    <div
      style={{
        background: colors.card,
        borderRadius: 22,
        padding: "18px 24px",
        boxShadow: "0 14px 40px rgba(59,42,74,.14)",
        borderLeft: `8px solid ${accent}`,
        opacity: a,
        translate: `${(1 - a) * 40}px 0px`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

const Side = ({children}: {readonly children: ReactNode}) => (
  <div style={{position: "absolute", left: 1230, right: 90, top: 220, display: "flex", flexDirection: "column", gap: 18}}>{children}</div>
);

const Shots = ({shots, accent}: {readonly shots: Shot[]; readonly accent: string}) => <GameShots shots={shots} left={90} top={220} width={1090} accent={accent} />;

// 1 · Portada ---------------------------------------------------------------
const cast = ["camila", "bruno", "sofi", "mateo", "sebas"];
const Portada = () => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames} = useVideoConfig();
  const title = spring({frame: frame - 4, fps, config: {damping: 18, stiffness: 90}});
  const leave = interpolate(frame, [durationInFrames - 10, durationInFrames], [1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"});
  return (
    <Backdrop>
      <div style={{position: "absolute", inset: 0, opacity: leave}}>
        <Img src={staticFile("personajes/courtyard.png")} style={{position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", opacity: 0.35, filter: "blur(3px)", scale: String(interpolate(frame, [0, durationInFrames], [1.04, 1.1]))}} />
        <div style={{position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(247,239,251,.94) 0%, rgba(247,239,251,.6) 50%, rgba(251,238,244,.2) 100%)"}} />
        <div style={{position: "absolute", left: 0, right: 0, top: 100, textAlign: "center", opacity: title, translate: `0px ${(1 - title) * 30}px`}}>
          <div style={{fontSize: 30, letterSpacing: 8, fontWeight: 700, color: colors.pink}}>JUEGO SERIO · PREVENCIÓN DEL GROOMING</div>
          <div style={{fontSize: 136, fontWeight: 820, letterSpacing: -4, marginTop: 6}}>Centinela 2.0</div>
          <div style={{fontSize: 44, fontWeight: 600, color: colors.soft}}>Un día con Sofi y sus amigos · 13 a 16 años</div>
        </div>
        <div style={{position: "absolute", left: 0, right: 0, bottom: -80, display: "flex", justifyContent: "center", alignItems: "flex-end"}}>
          {cast.map((id, i) => {
            const rise = spring({frame: frame - 10 - Math.abs(i - 2) * 4, fps, config: {damping: 16, stiffness: 90}});
            const main = id === "sofi";
            return (
              <Img
                key={id}
                src={staticFile(`personajes/${id}_v4.png`)}
                style={{width: main ? 390 : 330, marginLeft: i ? -60 : 0, zIndex: main ? 2 : 1, opacity: rise, translate: `0px ${(1 - rise) * 120}px`, filter: "drop-shadow(0 14px 26px rgba(59,42,74,.3))"}}
              />
            );
          })}
        </div>
      </div>
    </Backdrop>
  );
};

// 2 · Rutina ----------------------------------------------------------------
const rutinaCaps: Cue[] = [
  {from: 0, text: "Cada día empieza en la habitación de Sofi: celular, objetivo y mochila."},
  {from: 4.5, text: "Desayuna, camina al colegio y suena la campana."},
];
const steps = ["Habitación", "Desayuno", "Colegio y recreo", "Clase y despedida", "Discord y Arena", "Dormir"];
const Rutina = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const active = Math.min(3, Math.floor(frame / (fps * 2.3)));
  return (
    <Shell label={LABEL} section="Rutina diaria" title="Cinco jornadas, la misma rutina" accent={colors.lilac} captions={rutinaCaps} step={{index: 0, total: 5}}>
      <Shots accent={colors.lilac} shots={[{src: c("03_despertar"), from: 0}, {src: c("07_mochila"), from: 2.3}, {src: c("09_desayuno"), from: 4.6}, {src: c("11_colegio"), from: 6.9}]} />
      <Side>
        {steps.map((step, i) => (
          <Card key={step} delay={0.2 + i * 0.12} accent={i <= active ? colors.lilac : "rgba(138,95,176,.25)"} style={{padding: "12px 22px"}}>
            <div style={{fontSize: 30, fontWeight: i === active ? 800 : 560, color: i === active ? colors.lilac : colors.soft}}>
              {i + 1}. {step}
            </div>
          </Card>
        ))}
      </Side>
      <Sequence from={Math.round(6.9 * FPS)} layout="none">
        <Audio src={staticFile("audio/school_bell.wav")} volume={0.45} />
      </Sequence>
    </Shell>
  );
};

// 3 · Recreo ----------------------------------------------------------------
const recreoCaps: Cue[] = [
  {from: 0, text: "En el recreo, Sofi habla con sus cuatro amigos en cualquier orden."},
  {from: 5.5, text: "Cada uno vive una situación distinta. Mateo conoció en línea a Kairo."},
];
const friends = [
  {id: "mateo", name: "Mateo", text: "Kairo le hace regalos y le pide secretos"},
  {id: "camila", name: "Camila", text: "Le preguntan por los horarios de Mateo"},
  {id: "sebas", name: "Sebas", text: "Siente que debe conectarse siempre"},
  {id: "bruno", name: "Bruno", text: "Sostiene al grupo, puede equivocarse"},
];
const Recreo = () => (
  <Shell label={LABEL} section="Colegio" title="El recreo: escuchar a los amigos" accent={colors.pink} captions={recreoCaps} step={{index: 1, total: 5}}>
    <Shots accent={colors.pink} shots={[{src: c("12_patio_camila"), from: 0}, {src: c("13_patio_mateo"), from: 3.6}, {src: c("14_patio_bruno"), from: 7.2}]} />
    <Side>
      {friends.map((f, i) => (
        <Card key={f.id} delay={0.3 + i * 0.35} accent={i === 0 ? colors.pink : colors.lilac} style={{display: "flex", alignItems: "center", gap: 18, padding: "10px 18px"}}>
          <div style={{width: 92, height: 92, borderRadius: 99, overflow: "hidden", background: "#efe4f6", flexShrink: 0}}>
            <Img src={staticFile(`personajes/${f.id}_v4.png`)} style={{width: 170, marginLeft: -39, marginTop: -6}} />
          </div>
          <div>
            <div style={{fontSize: 30, fontWeight: 800}}>{f.name}</div>
            <div style={{fontSize: 24, color: colors.soft, lineHeight: 1.25}}>{f.text}</div>
          </div>
        </Card>
      ))}
    </Side>
  </Shell>
);

// 4 · Decisión y tutor --------------------------------------------------------
const decisionCaps: Cue[] = [
  {from: 0, text: "En los momentos clave, el jugador elige qué responde Sofi."},
  {from: 3.6, text: "Si duda, puede pedir un consejo al tutor: orienta, pero no elige por él."},
  {from: 7.4, text: "Cada respuesta se clasifica y cambia lo que pasa después. No hay puntaje."},
];
const Chip = ({text, color, delay}: {readonly text: string; readonly color: string; readonly delay: number}) => {
  const a = useAppear(delay);
  return <div style={{padding: "10px 20px", borderRadius: 99, background: color, color: "#fff", fontSize: 25, fontWeight: 700, opacity: a, scale: String(0.8 + a * 0.2)}}>{text}</div>;
};
const Decision = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const picked = frame > 6.6 * fps;
  return (
    <Shell label={LABEL} section="Decisiones y apoyo" title="Decidir sin respuestas correctas a la vista" accent={colors.teal} captions={decisionCaps} step={{index: 2, total: 5}}>
      <Shots accent={colors.teal} shots={[{src: c("26_discord_decision"), from: 0}, {src: c("13_patio_mateo"), from: 6.6}]} />
      <Side>
        <Card delay={0.2} accent={colors.ink}>
          <div style={{fontSize: 22, letterSpacing: 2, fontWeight: 700, color: colors.muted}}>MATEO</div>
          <div style={{fontSize: 27, fontWeight: 600, lineHeight: 1.3}}>“Kairo me regaló una skin… pero dijo que no le cuente a nadie.”</div>
        </Card>
        {[
          {k: "A", t: "Eso no está bien. Hablemos con alguien."},
          {k: "B", t: "Tranqui, es solo un regalo."},
        ].map((o, i) => (
          <Card key={o.k} delay={0.9 + i * 0.25} accent={picked && i === 0 ? colors.teal : "rgba(138,95,176,.3)"} style={{display: "flex", gap: 16, alignItems: "center", padding: "12px 20px", background: picked && i === 0 ? "#e3f4f1" : colors.card}}>
            <div style={{width: 46, height: 46, borderRadius: 99, background: picked && i === 0 ? colors.teal : colors.lilac, color: "#fff", fontSize: 26, fontWeight: 800, display: "flex", alignItems: "center", justifyContent: "center"}}>{o.k}</div>
            <div style={{fontSize: 27, fontWeight: 600}}>{o.t}</div>
          </Card>
        ))}
        <Card delay={3.6} accent={colors.amber} style={{background: "#fff4e6"}}>
          <div style={{fontSize: 22, letterSpacing: 2, fontWeight: 700, color: colors.amber}}>CONSEJO DEL TUTOR</div>
          <div style={{fontSize: 25, lineHeight: 1.3}}>Fíjate si alguien pide secretos a cambio de regalos. La decisión es tuya.</div>
        </Card>
        <div style={{display: "flex", gap: 10, flexWrap: "wrap"}}>
          <Chip text="Protectora" color={colors.teal} delay={7.4} />
          <Chip text="Con límite" color={colors.amber} delay={7.7} />
          <Chip text="De riesgo" color={colors.pink} delay={8.0} />
        </div>
      </Side>
      <Audio src={staticFile("audio/notification.wav")} volume={0.5} />
    </Shell>
  );
};

// 5 · Discord y Arena ---------------------------------------------------------
const arenaCaps: Cue[] = [
  {from: 0, text: "En la noche, Sofi abre Discord y juega con el grupo una partida corta."},
  {from: 4.4, text: "Arena 5v5: gana quien llegue a 5 bajas o tenga más al minuto."},
];
const Arena = () => (
  <Shell label={LABEL} section="PC · Discord · Arena" title="El espacio donde también aparece Kairo" accent={colors.amber} captions={arenaCaps} step={{index: 3, total: 5}}>
    <Shots accent={colors.amber} shots={[{src: c("28_discord_respuesta"), from: 0}, {src: c("29_clases"), from: 2.3}, {src: c("31_moba_combate"), from: 4.4}, {src: c("32_moba_resultado"), from: 6.9}]} />
    <Side>
      {["Chat del grupo en Discord", "Elegir clase: Atacante, Defensor o Soporte", "5 bajas o 60 segundos", "Sin torres ni bases", "Camila comenta el resultado"].map((t, i) => (
        <Card key={t} delay={0.3 + i * 0.45} accent={colors.amber} style={{padding: "14px 22px"}}>
          <div style={{fontSize: 28, fontWeight: 600}}>{t}</div>
        </Card>
      ))}
    </Side>
    <Audio src={staticFile("audio/arena_loop.wav")} volume={(f) => Math.min(1, f / 15, (9 * FPS - f) / 15) * 0.2} />
    <Sequence from={Math.round(6.9 * FPS)} layout="none">
      <Audio src={staticFile("audio/result.wav")} volume={0.5} />
    </Sequence>
  </Shell>
);

// 6 · Finales -----------------------------------------------------------------
const finalesCaps: Cue[] = [
  {from: 0, text: "El final depende de lo que el jugador hizo, no de un puntaje."},
  {from: 5.2, text: "Al cierre se muestra la clasificación de cada decisión y dónde pedir ayuda."},
];
const endings = [
  {code: "F01", name: "Apoyo iniciado", text: "Sofi y sus amigos hablaron con el tutor.", color: colors.teal},
  {code: "F02", name: "Un límite y un paso pendiente", text: "Bloqueo y privacidad en la PC; el grupo mantuvo la confianza.", color: colors.amber},
  {code: "F03", name: "Seguimos aquí", text: "Quedan pasos pendientes; todavía se puede pedir ayuda.", color: colors.pink},
];
const Finales = () => (
  <Shell label={LABEL} section="Cierre" title="Tres finales posibles" accent={colors.teal} captions={finalesCaps} step={{index: 4, total: 5}}>
    <div style={{position: "absolute", left: 90, right: 90, top: 230, display: "flex", gap: 34}}>
      {endings.map((e, i) => {
        const a = useAppear(0.3 + i * 0.6);
        return (
          <div key={e.code} style={{flex: 1, height: 520, borderRadius: 28, background: colors.card, boxShadow: "0 18px 50px rgba(59,42,74,.16)", padding: 40, boxSizing: "border-box", borderTop: `14px solid ${e.color}`, opacity: a, translate: `0px ${(1 - a) * 60}px`}}>
            <div style={{fontSize: 92, fontWeight: 850, color: e.color, letterSpacing: -2}}>{e.code}</div>
            <div style={{fontSize: 40, fontWeight: 800, marginTop: 10, lineHeight: 1.15}}>{e.name}</div>
            <div style={{fontSize: 30, color: colors.soft, marginTop: 22, lineHeight: 1.35}}>{e.text}</div>
          </div>
        );
      })}
    </div>
  </Shell>
);

// 7 · Cierre ------------------------------------------------------------------
const Cierre = () => {
  const frame = useCurrentFrame();
  const a = useAppear(0.2);
  const b = useAppear(1.2);
  const {durationInFrames} = useVideoConfig();
  const fade = interpolate(frame, [durationInFrames - 15, durationInFrames], [1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease});
  return (
    <Backdrop>
      <div style={{position: "absolute", inset: 0, display: "flex", alignItems: "center", gap: 70, padding: "0 140px", opacity: fade}}>
        <Img src={staticFile("personajes/sofi_v4.png")} style={{height: 900, marginTop: 180, opacity: a, translate: `${(1 - a) * -60}px 0px`}} />
        <div>
          <div style={{fontSize: 76, fontWeight: 820, lineHeight: 1.08, letterSpacing: -2, opacity: a}}>Aprender con la experiencia, no con el sermón</div>
          <div style={{fontSize: 40, color: colors.soft, marginTop: 30, lineHeight: 1.35, opacity: b}}>
            Escuchar sin juzgar · poner límites en línea ·<br />
            <span style={{color: colors.pink, fontWeight: 800}}>pedir ayuda a un adulto de confianza</span>
          </div>
          <div style={{fontSize: 30, letterSpacing: 5, fontWeight: 700, color: colors.lilac, marginTop: 50, opacity: b}}>CENTINELA 2.0 · GODOT 4</div>
        </div>
      </div>
    </Backdrop>
  );
};

const map = {portada: Portada, rutina: Rutina, recreo: Recreo, decision: Decision, arena: Arena, finales: Finales, cierre: Cierre};

const Demo60 = () => {
  const arenaStart = (5 + 9 + 11 + 11) * FPS;
  const arenaEnd = arenaStart + 9 * FPS;
  return (
    <>
      <Series>
        {scenes.map((scene) => {
          const Scene = map[scene.id];
          return (
            <Series.Sequence key={scene.id} name={scene.id} durationInFrames={scene.seconds * FPS} premountFor={FPS}>
              <Scene />
            </Series.Sequence>
          );
        })}
      </Series>
      <Sequence from={0} durationInFrames={arenaStart} layout="none">
        <Audio src={staticFile("audio/explore_loop.wav")} loop volume={(f) => Math.min(1, f / 20, (arenaStart - f) / 15) * 0.16} />
      </Sequence>
      <Sequence from={arenaEnd} durationInFrames={DEMO_FRAMES - arenaEnd} layout="none">
        <Audio src={staticFile("audio/explore_loop.wav")} loop volume={(f) => Math.min(1, f / 15, (DEMO_FRAMES - arenaEnd - f) / 20) * 0.16} />
      </Sequence>
    </>
  );
};

export const Demo60Composition = () => <Composition id="Demo60" component={Demo60} durationInFrames={DEMO_FRAMES} fps={FPS} width={WIDTH} height={HEIGHT} />;
