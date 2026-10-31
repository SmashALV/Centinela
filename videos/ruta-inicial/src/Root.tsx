import {Demo60Composition} from "./demo/Demo60";
import {MainComposition, SceneCompositions} from "./RutaInicial";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <MainComposition />
      <SceneCompositions />
      <Demo60Composition />
    </>
  );
};
