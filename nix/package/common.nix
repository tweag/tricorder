let
  default-ghc-version = "9.10.3";
  additional-ghc-versions = [
    "9.6.7"
    "9.8.4"
    "9.12.4"
  ];
  ghc-versions = [ default-ghc-version ] ++ additional-ghc-versions;

  # Missed-specialisation warnings fire on imported overloaded functions (e.g.
  # realToFrac, Data.Fixed instances, prometheus exporters) that we can't
  # annotate with INLINABLE. They only appear under optimization and aren't
  # actionable.
  warnings = [
    "-Weverything"
    "-Wno-unsafe"
    "-Wno-missing-safe-haskell-mode"
    "-Wno-monomorphism-restriction"
    "-Wno-missing-kind-signatures"
    "-Wno-missing-local-signatures"
    "-Wno-missing-import-lists"
    "-Wno-implicit-prelude"
    "-Wno-unticked-promoted-constructors"
    "-Wno-unused-packages"
    "-Wno-all-missed-specialisations"
    "-Wno-missed-specialisations"
  ];
in
{
  author = "Victor Nascimento Bakke";
  maintainer = "victor.bakke@tweag.io";
  license = "MIT";
  license-file = "LICENSE";
  language = "GHC2021";

  inherit
    default-ghc-version
    additional-ghc-versions
    ghc-versions
    ;

  tested-with = map (v: "GHC == ${v}") ghc-versions;

  options = {
    inherit warnings;
    ghc-options = warnings ++ [
      "-fplugin=Effectful.Plugin"
      "-threaded"
    ];
    when = [
      {
        condition = "impl(GHC >= 9.8)";
        ghc-options = [
          "-Wno-missing-poly-kind-signatures"
          "-Wno-missing-role-annotations"
        ];
      }
    ];
  };

  default-extensions = [
    "BlockArguments"
    "DataKinds"
    "DeriveAnyClass"
    "DerivingStrategies"
    "DerivingVia"
    "DuplicateRecordFields"
    "FlexibleContexts"
    "GADTs"
    "LambdaCase"
    "MultiWayIf"
    "OverloadedLabels"
    "OverloadedRecordDot"
    "OverloadedStrings"
    "StrictData"
    "TemplateHaskell"
    "TypeFamilies"
  ];

  packageNames = [
    "atelier-core"
    "atelier-db"
    "atelier-prelude"
    "atelier-testing"
    "tricorder"
    "tricorder-mcp"
  ];
}
