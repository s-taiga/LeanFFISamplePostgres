import «PostgreSample»

def main : IO Unit := do
  let ⟨salary, name⟩ ← GetPostgresEmployeeCont ()
  IO.println s!"salary: {salary}, name: {name}"
