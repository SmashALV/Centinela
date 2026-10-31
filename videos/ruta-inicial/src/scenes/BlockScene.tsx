import {Audio, Sequence, staticFile, useVideoConfig} from "remotion";
import {GameShots} from "../components/GameShots";
import {Shell} from "../components/Shell";
import {SidePanel} from "../components/SidePanel";
import type {Block} from "../data";

export const BlockScene = ({block, index, total}: {readonly block: Block; readonly index: number; readonly total: number}) => {
  const {fps} = useVideoConfig();
  return (
    <Shell section={block.section} title={block.title} accent={block.accent} captions={block.captions} step={{index, total}}>
      <GameShots shots={block.shots} left={90} top={200} width={1180} accent={block.accent} />
      {block.side ? <SidePanel side={block.side} accent={block.accent} left={1320} top={214} width={510} /> : null}
      {(block.sounds ?? []).map((sound) => (
        <Sequence key={sound.src + sound.from} from={Math.round(sound.from * fps)} layout="none">
          <Audio src={staticFile(sound.src)} volume={sound.volume ?? 0.6} />
        </Sequence>
      ))}
    </Shell>
  );
};
