import {Audio, Composition, Folder, Series, Sequence, staticFile, useVideoConfig} from "remotion";
import {CLOSING_SECONDS, COVER_SECONDS, blocks} from "./data";
import {BlockScene} from "./scenes/BlockScene";
import {Closing} from "./scenes/Closing";
import {Cover} from "./scenes/Cover";
import {FPS, HEIGHT, WIDTH} from "./theme";

export const TOTAL_FRAMES = (COVER_SECONDS + CLOSING_SECONDS + blocks.reduce((sum, block) => sum + block.seconds, 0)) * FPS;

// Música de fondo suave: exploración en todo el video, salvo el bloque de la Arena.
const Music = () => {
  const {fps} = useVideoConfig();
  let cursor = COVER_SECONDS * fps;
  const spans: {from: number; frames: number; src: string}[] = [];
  let exploreStart = 0;
  for (const block of blocks) {
    const frames = block.seconds * fps;
    if (block.music === "arena") {
      spans.push({from: exploreStart, frames: cursor - exploreStart, src: "audio/explore_loop.wav"});
      spans.push({from: cursor, frames, src: "audio/arena_loop.wav"});
      exploreStart = cursor + frames;
    }
    cursor += frames;
  }
  spans.push({from: exploreStart, frames: cursor + CLOSING_SECONDS * fps - exploreStart, src: "audio/explore_loop.wav"});
  return (
    <>
      {spans.map((span) => (
        <Sequence key={span.from} from={span.from} durationInFrames={span.frames} layout="none">
          <Audio src={staticFile(span.src)} loop volume={(f) => Math.min(1, f / 20, (span.frames - f) / 20) * 0.18} />
        </Sequence>
      ))}
    </>
  );
};

const RutaInicial = () => (
  <>
    <Series>
      <Series.Sequence name="Portada" durationInFrames={COVER_SECONDS * FPS} premountFor={FPS}>
        <Cover />
      </Series.Sequence>
      {blocks.map((block, index) => (
        <Series.Sequence key={block.id} name={block.title} durationInFrames={block.seconds * FPS} premountFor={FPS}>
          <BlockScene block={block} index={index} total={blocks.length} />
        </Series.Sequence>
      ))}
      <Series.Sequence name="Cierre" durationInFrames={CLOSING_SECONDS * FPS} premountFor={FPS}>
        <Closing />
      </Series.Sequence>
    </Series>
    <Music />
  </>
);

export const MainComposition = () => (
  <Composition id="RutaInicial" component={RutaInicial} durationInFrames={TOTAL_FRAMES} fps={FPS} width={WIDTH} height={HEIGHT} />
);

export const SceneCompositions = () => (
  <Folder name="Bloques">
    <Composition id="Portada" component={Cover} durationInFrames={COVER_SECONDS * FPS} fps={FPS} width={WIDTH} height={HEIGHT} />
    {blocks.map((block, index) => (
      <Composition
        key={block.id}
        id={`Bloque-${block.id}`}
        component={BlockScene}
        defaultProps={{block, index, total: blocks.length}}
        durationInFrames={block.seconds * FPS}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
      />
    ))}
    <Composition id="Cierre" component={Closing} durationInFrames={CLOSING_SECONDS * FPS} fps={FPS} width={WIDTH} height={HEIGHT} />
  </Folder>
);
