// Contenido de cada bloque. Los tiempos están en segundos desde el inicio del bloque.
export type Shot = {src: string; from: number};
export type Cue = {from: number; text: string};
export type Side =
  | {kind: "keys"; items: {key: string; label: string}[]}
  | {kind: "points"; items: string[]}
  | {kind: "options"; items: {letter: string; text: string}[]; pick: number; pickFrom: number}
  | {kind: "arena"; switchAt: number; rules: string[]};
export type SoundCue = {src: string; from: number; volume?: number};

export type Block = {
  id: string;
  section: string;
  title: string;
  accent: string;
  seconds: number;
  shots: Shot[];
  side?: Side;
  captions: Cue[];
  sounds?: SoundCue[];
  music?: "explore" | "arena";
};

const c = (name: string) => `capturas/${name}.png`;

export const blocks: Block[] = [
  {
    id: "menu",
    section: "Inicio",
    title: "Menú y ranuras de guardado",
    accent: "#8a5fb0",
    seconds: 8,
    shots: [{src: c("01_menu"), from: 0}],
    side: {kind: "points", items: ["Tres ranuras de guardado", "Rehacer: vuelve al prólogo", "Borrar: deja la ranura vacía", "Guarda solo en cada paso importante"]},
    captions: [
      {from: 0, text: "Centinela 2.0 es un juego narrativo 2D sobre la prevención del grooming."},
      {from: 4, text: "Hay tres ranuras. Rehacer reinicia desde el prólogo y Borrar vacía la ranura."},
    ],
  },
  {
    id: "prologo",
    section: "Prólogo",
    title: "Sofi y sus amigos",
    accent: "#d9679b",
    seconds: 9,
    shots: [{src: c("02_prologo"), from: 0}],
    side: {kind: "keys", items: [{key: "Auto", label: "El texto avanza solo"}, {key: "Clic · Enter", label: "Adelantar"}, {key: "P", label: "Pausar la lectura"}]},
    captions: [
      {from: 0, text: "El prólogo presenta a Sofi, de 15 años, y a Mateo, Camila, Bruno y Sebas."},
      {from: 4.5, text: "La idea central: explorar, escuchar y decidir cómo responder."},
    ],
  },
  {
    id: "habitacion",
    section: "Mañana · Habitación",
    title: "Despertar y primeros controles",
    accent: "#8a5fb0",
    seconds: 15,
    shots: [
      {src: c("03_despertar"), from: 0},
      {src: c("04_habitacion"), from: 4},
      {src: c("05_celular"), from: 8},
      {src: c("06_objetivo_pistas"), from: 11.5},
    ],
    side: {kind: "keys", items: [{key: "WASD", label: "Moverse"}, {key: "F", label: "Interactuar"}, {key: "E", label: "Celular"}, {key: "Tab", label: "Objetivo y pistas"}, {key: "P", label: "Pausa"}]},
    captions: [
      {from: 0, text: "Sofi despierta. Los diálogos son de novela visual, con el nombre de quien habla."},
      {from: 4, text: "En el mapa me muevo con WASD. Arriba siempre aparece el objetivo."},
      {from: 8, text: "Con E abro el celular: Mateo propone jugar una partida esta noche."},
      {from: 11.5, text: "Tab muestra el objetivo y dos pistas: H1 para observar y H2 para comprender."},
    ],
    sounds: [{src: "audio/notification.wav", from: 8, volume: 0.5}],
  },
  {
    id: "salir",
    section: "Mañana · Habitación",
    title: "Observar y salir por el borde",
    accent: "#8a5fb0",
    seconds: 10,
    shots: [
      {src: c("08_foto"), from: 0},
      {src: c("07_mochila"), from: 5},
    ],
    side: {kind: "points", items: ["Objetos para observar con F", "Sin puertas: el escenario cambia en el borde", "Si falta algo, el juego avisa", "Las pistas no restan puntos"]},
    captions: [
      {from: 0, text: "La foto recuerda que el grupo juega junto, pero cada uno necesita su espacio."},
      {from: 5, text: "Recojo la mochila y salgo por el borde derecho. Si falta algo, el juego avisa."},
    ],
  },
  {
    id: "desayuno",
    section: "Mañana · Casa y calle",
    title: "Desayuno y camino al colegio",
    accent: "#d98b3a",
    seconds: 10,
    shots: [
      {src: c("09_desayuno"), from: 0},
      {src: c("10_calle_manana"), from: 5},
    ],
    side: {kind: "points", items: ["Escenas de rutina que cambian cada día", "Ida al colegio: hacia la derecha", "Regreso a casa: hacia la izquierda"]},
    captions: [
      {from: 0, text: "Sofi desayuna. Estas escenas de rutina cambian un poco cada día."},
      {from: 5, text: "La calle une la casa con el colegio. A la ida se camina hacia la derecha."},
    ],
  },
  {
    id: "colegio",
    section: "Colegio · Entrada",
    title: "El grupo de amigos",
    accent: "#3fa79b",
    seconds: 15,
    shots: [
      {src: c("11_colegio"), from: 0},
      {src: c("12_patio_camila"), from: 4},
      {src: c("13_patio_mateo"), from: 8},
      {src: c("14_patio_bruno"), from: 11.5},
    ],
    side: {kind: "points", items: ["F: hablar con el grupo", "Arriba: salón de clase", "Izquierda: tutoría", "Derecha: sala de cómputo"]},
    captions: [
      {from: 0, text: "En la entrada espera el grupo. Me acerco y pulso F."},
      {from: 4, text: "Camila llama a Sofi: Mateo y Bruno ya empezaron a discutir."},
      {from: 8, text: "Bromean sobre quién juega mejor. Es una amistad normal, con bromas y roces."},
      {from: 11.5, text: "Sebas apoya a Mateo. Todos quieren jugar más tarde."},
    ],
  },
  {
    id: "apoyo",
    section: "Colegio · Opcional",
    title: "Tutoría y sala de cómputo",
    accent: "#3fa79b",
    seconds: 10,
    shots: [
      {src: c("16_tutoria_cartel"), from: 0},
      {src: c("17_sala_computo"), from: 5.5},
    ],
    side: {kind: "points", items: ["Pedir apoyo es posible desde el primer día", "Las PC están en el cuarto y en cómputo", "Cada observación queda guardada"]},
    captions: [
      {from: 0, text: "En tutoría, un cartel recuerda que se puede hablar con un adulto de confianza."},
      {from: 5.5, text: "La sala de cómputo es el otro lugar con computadora, además del cuarto de Sofi."},
    ],
  },
  {
    id: "clase",
    section: "Colegio · Clase",
    title: "Clase y campana",
    accent: "#3fa79b",
    seconds: 11,
    shots: [
      {src: c("18_salon"), from: 0},
      {src: c("19_clase_mateo"), from: 3.5},
      {src: c("20_campana"), from: 7.5},
    ],
    side: {kind: "points", items: ["Se entra a clase después de hablar con el grupo", "F en el pupitre: comienza la clase", "La campana cambia el objetivo"]},
    captions: [
      {from: 0, text: "Para entrar a clase hay que hablar antes con el grupo."},
      {from: 3.5, text: "En clase, Mateo y Camila conversan en voz baja sobre la tarea."},
      {from: 7.5, text: "Suena la campana. Ahora hay que salir por abajo para despedirse."},
    ],
    sounds: [{src: "audio/school_bell.wav", from: 7.5, volume: 0.7}],
  },
  {
    id: "despedida",
    section: "Tarde",
    title: "Despedida y regreso al atardecer",
    accent: "#d98b3a",
    seconds: 10,
    shots: [
      {src: c("21_despedida"), from: 0},
      {src: c("22_calle_atardecer"), from: 5},
    ],
    side: {kind: "points", items: ["Cada amigo toma su camino", "La luz cambia al atardecer", "Hacia el colegio, el juego recuerda que las clases terminaron"]},
    captions: [
      {from: 0, text: "Cada amigo se despide y toma su camino."},
      {from: 5, text: "La luz pasa al atardecer. El regreso a casa es hacia la izquierda."},
    ],
  },
  {
    id: "escritorio",
    section: "Noche · Casa",
    title: "Cena y escritorio de Sofi",
    accent: "#8a5fb0",
    seconds: 11,
    shots: [
      {src: c("23_cena"), from: 0},
      {src: c("24_escritorio_bloqueado"), from: 4.5},
    ],
    side: {kind: "points", items: ["Discord: chat del grupo", "Arena 5v5: se habilita después del chat", "Revisar mi privacidad (opcional)", "Apagar pantalla y seguir recorriendo"]},
    captions: [
      {from: 0, text: "Sofi cena y quiere ver si sus amigos ya están conectados."},
      {from: 4.5, text: "En el escritorio están Discord y la Arena 5v5. La Arena se habilita después del chat."},
    ],
  },
  {
    id: "discord",
    section: "Noche · Discord",
    title: "La primera decisión",
    accent: "#d9679b",
    seconds: 17,
    shots: [
      {src: c("25_discord_inicio"), from: 0},
      {src: c("26_discord_decision"), from: 4},
      {src: c("28_discord_respuesta"), from: 12},
    ],
    side: {
      kind: "options",
      items: [
        {letter: "A", text: "«Ya estoy, gente. ¿Le damos?»"},
        {letter: "B", text: "«Oe, tranquilos, recién entro y ya están peleando»"},
        {letter: "C", text: "«Mateo, espero que hoy sí nos hagas ganar»"},
      ],
      pick: 1,
      pickFrom: 8,
    },
    captions: [
      {from: 0, text: "En Discord, el grupo se organiza para jugar. Solo falta Sofi."},
      {from: 4, text: "Esta es la primera decisión del juego, con tres respuestas posibles."},
      {from: 8, text: "Elijo B: calmar la discusión entre Mateo y Bruno."},
      {from: 12, text: "Cada respuesta provoca una reacción distinta. Aquí Bruno responde: «Ya, ya, paz»."},
    ],
    sounds: [{src: "audio/notification.wav", from: 12, volume: 0.5}],
  },
  {
    id: "arena",
    section: "Noche · Arena 5v5",
    title: "La partida con el grupo",
    accent: "#3fa79b",
    seconds: 18,
    shots: [
      {src: c("29_clases"), from: 0},
      {src: c("30_moba_inicio"), from: 5},
      {src: c("31_moba_combate"), from: 9},
      {src: c("32_moba_resultado"), from: 13.5},
    ],
    side: {
      kind: "arena",
      switchAt: 5,
      rules: ["5 contra 5, sin torres ni bases", "Gana el primero en llegar a 5 bajas", "A los 60 s gana quien tenga más bajas; si hay igualdad, es empate", "Clic izquierdo: atacar · Q: habilidad"],
    },
    captions: [
      {from: 0, text: "Hay tres clases, y cada una tiene su habilidad Q."},
      {from: 5, text: "Cinco contra cinco, sin torres ni bases. Gana el primer equipo con cinco bajas."},
      {from: 9, text: "Ataco con clic izquierdo y uso Q. El HUD muestra tiempo, marcador, vida y recarga."},
      {from: 13.5, text: "El rival llegó primero a cinco bajas: esta vez perdimos 3 a 5."},
    ],
    music: "arena",
    sounds: [{src: "audio/result.wav", from: 13.5, volume: 0.6}],
  },
  {
    id: "dormir",
    section: "Noche · Fin del día",
    title: "Reacción del grupo y descanso",
    accent: "#8a5fb0",
    seconds: 13,
    shots: [
      {src: c("33_reaccion_camila"), from: 0},
      {src: c("34_hora_dormir"), from: 4},
      {src: c("35_dormir"), from: 7.5},
      {src: c("36_amanece"), from: 10},
    ],
    side: {kind: "points", items: ["La reacción cambia según el resultado y la clase", "F en la cama: dormir", "El día solo avanza al dormir"]},
    captions: [
      {from: 0, text: "Camila comenta la partida. Su mensaje cambia según el resultado y la clase."},
      {from: 4, text: "Sofi se despide del grupo. Me acerco a la cama para dormir."},
      {from: 7.5, text: "El día solo avanza cuando Sofi duerme."},
      {from: 10, text: "La pantalla pasa de la noche a la mañana."},
    ],
  },
];

export const COVER_SECONDS = 6;
export const CLOSING_SECONDS = 13;
export const TRANSITION_FRAMES = 12;
