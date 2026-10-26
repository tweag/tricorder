{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  ({
    flags = {};
    package = {
      specVersion = "2.2";
      identifier = { name = "stm-chans"; version = "3.0.0.11"; };
      license = "BSD-3-Clause";
      copyright = "2011–2025 wren romano";
      maintainer = "wren@cpan.org";
      author = "wren gayle romano, Thomas DuBuisson";
      homepage = "https://wrengr.org/software/hackage.html";
      url = "";
      synopsis = "Additional types of channels for STM.";
      description = "Additional types of channels for STM.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/stm-chans-3.0.0.11.tar.gz";
      sha256 = "b293ef847e3c7aa0800d20b18912a069ba6951e7d2e35171acecd6ff937975f2";
    });
  }) // {
    package-description-override = "Cabal-Version:  2.2\n-- Cabal >=2.2 is required for:\n--    <https://cabal.readthedocs.io/en/latest/cabal-package.html#common-stanzas>\n-- Since 2.1, the Cabal-Version must be the absolutely first thing\n-- in the file, even before comments.  Also, no longer uses \">=\".\n--    <https://github.com/haskell/cabal/issues/4899>\n\n----------------------------------------------------------------\n-- wren gayle romano <wren@cpan.org>                ~ 2026-02-26\n----------------------------------------------------------------\n\nName:           stm-chans\nVersion:        3.0.0.11\nBuild-Type:     Simple\nStability:      provisional\nHomepage:       https://wrengr.org/software/hackage.html\nBug-Reports:    https://github.com/wrengr/stm-chans/issues\nAuthor:         wren gayle romano, Thomas DuBuisson\nMaintainer:     wren@cpan.org\nCopyright:      2011–2025 wren romano\n-- Cabal-2.2 requires us to say \"BSD-3-Clause\" not \"BSD3\"\nLicense:        BSD-3-Clause\nLicense-File:   LICENSE\n\nCategory:       Concurrency\nSynopsis:       Additional types of channels for STM.\nDescription:    Additional types of channels for STM.\n\nExtra-source-files:\n    AUTHORS, README.md, CHANGELOG\n\n-- This used to be tested on 7.8.3 and 7.10.1, but we don't verify that by CI.\n-- <https://github.com/wrengr/stm-chans/actions?query=workflow%3Aci>\nTested-With:\n    GHC ==8.0.2,\n    GHC ==8.2.2,\n    GHC ==8.4.4,\n    GHC ==8.6.5,\n    GHC ==8.8.4,\n    GHC ==8.10.3,\n    GHC ==9.0.1,\n    GHC ==9.2.4,\n    GHC ==9.4.8,\n    GHC ==9.6.5,\n    GHC ==9.8.2,\n    GHC ==9.10.1,\n    GHC ==9.12.1,\n    GHC ==9.14.1\n\n----------------------------------------------------------------\nSource-Repository head\n    Type:     git\n    Location: https://github.com/wrengr/stm-chans.git\n\n----------------------------------------------------------------\nLibrary\n    Default-Language: Haskell2010\n    -- N.B., the following versions are required for:\n    -- * stm >= 2.4:   T{,B}Queue and newBroadcastTChan{,IO}\n    -- * stm >= 2.3.0: fast tryReadTChan, peekTChan, tryPeekTChan,\n    --         tryReadTMVar, modifyTVar, modifyTVar', swapTVar.\n    -- * stm >= 2.1.2: fast readTVarIO.\n    --\n    -- Not sure what the real minbound is for base...\n    Build-Depends: base >= 4.1 && < 5\n                 , stm  >= 2.4\n\n    Hs-Source-Dirs:  src\n    Exposed-Modules: Control.Concurrent.STM.TBChan\n                   , Control.Concurrent.STM.TBMChan\n                   , Control.Concurrent.STM.TMChan\n                   , Control.Concurrent.STM.TBMQueue\n                   , Control.Concurrent.STM.TMQueue\n\n----------------------------------------------------------------\n----------------------------------------------------------- fin.\n";
  }