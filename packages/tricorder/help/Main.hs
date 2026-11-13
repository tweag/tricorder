import System.IO qualified as IO

import Tricorder.CLI.Docs (renderReference)


main :: IO ()
main = IO.putStrLn $ toString renderReference
