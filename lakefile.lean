import Lake
open Lake DSL

package «postgre_sample» where
  -- add package configuration options here
  moreLinkArgs := #[
    -- "-lpqxx",
    "-lpq",
    "-L/usr/include/postgresql"
  ]

def inputTextFile (path : FilePath) : SpawnM (BuildJob FilePath) :=
  Job.async <| (path, ·) <$> computeTrace (TextFilePath.mk path)

/--
Given a Lean module named `M.lean`, build a C shim named `M.shim.c`
-/
@[inline] private def buildCO (mod : Module) (shouldExport : Bool) : FetchM (BuildJob FilePath) := do
  let cFile := mod.srcPath "shim.c"
  let irCFile := mod.irPath "shim.c"
  let cJob ← -- get or create shim.c file (we no shim.c is found, create an empty one to make lake happy)
    if (← cFile.pathExists) then
      proc { cmd := "cp", args := #[cFile.toString, irCFile.toString]}
      inputTextFile irCFile
    else
      logVerbose s!"creating empty shim.c file at {irCFile}"
      let _<-  proc { cmd := "touch", args := #[irCFile.toString] }
      inputTextFile irCFile

  let oFile := mod.irPath s!"shim.c.o.{if shouldExport then "export" else "noexport"}"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString] ++ mod.weakLeancArgs
  -- let cc := (← IO.getEnv "CC").getD "g++"
  let cc := (← IO.getEnv "CC").getD "clang"
  -- let cc := "g++"/
  -- let leancArgs := mod.leancArgs.push "-fPIC"
  let leancArgs := if shouldExport then mod.leancArgs.push "-DLEAN_EXPORTING" else mod.leancArgs
  buildO oFile cJob weakArgs leancArgs cc getLeanTrace

module_facet shim.c.o.export mod : FilePath := buildCO mod true
module_facet shim.c.o.noexport mod : FilePath :=  buildCO mod false

lean_lib «PostgreSample» where
  -- add library configuration options here
  nativeFacets := (#[Module.oExportFacet, if · then `shim.c.o.export else `shim.c.o.noexport])

@[default_target]
lean_exe «postgre_sample» where
  root := `Main
