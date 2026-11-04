# DirectStiffness

Implementação em Julia do **Método da Rigidez Direta** para análise estrutural (disciplina Teoria 2, UnB).
Alvo atual: **treliça 2D**. A arquitetura já prevê treliça 3D e pórtico 2D/3D.

- Unidades dos exemplos: kgf e cm. Eixos globais: x para a direita, y para cima.
- Julia 1.13. Código e identificadores em inglês; discussão com o autor em português.
- Rodar: `julia src/Direct_Stiffness.jl [inputs/arquivo.toml]` (padrão: `inputs/truss.toml`); gera `outputs/<nome do input>.txt`.
  `julia src/test.jl` imprime o mesmo relatório na tela. Funciona de qualquer pasta (usa `@__DIR__`).

## Estado atual

| Etapa | Arquivo | Estado |
|---|---|---|
| Leitura do TOML | `src/assemble.jl` (`read_model`) | pronto |
| Montagem do modelo (`Structure`) | `src/assemble.jl` (`build_structure`) | pronto |
| Matriz de rigidez global (esparsa) | `src/assemble.jl` | pronto |
| Vetor de deslocamentos prescritos `u_pre` | `src/boundary.jl` | pronto |
| Vetor de forças `F` | `src/types/external_forces.jl` | pronto para cargas nodais (`nodal_loads`) |
| Solver (partição) | `src/solver.jl` (`solve_system`) | pronto |
| Relatório em texto | `src/report.jl` + `run_analysis` | pronto (sem esforços internos) |
| Esforços internos | `src/internal_forces.jl` | vazio |
| Pórtico (`Frame2D/3D`), rótulas, cargas de barra | — | não iniciado |

Único caso verificado: a treliça de `inputs/truss.toml`. O termo `K[1,1] = 5.625e7` foi conferido à mão
(barra horizontal `4.5e7` + barra a 60° `4.5e7·cos²60° = 1.125e7`). A simetria e o equilíbrio de
corpo rígido da K inteira **ainda não foram verificados**, e não há testes automatizados.

## Fluxo de dados

```
TOML ──read_model──▶ data
data ──build_structure──▶ Structure{Element{G,S}}
Structure ──build_global_stiffness_matrix──▶ K (esparsa)
mesh["boundary"] ──build_displacement_vector──▶ u_pre   (NaN = GDL livre)
data["loads"]    ──build_F_vector──▶ F
(K, F, u_pre) ──solve_system──▶ u, R
(s, F, u_pre, u, R) ──write_report──▶ outputs/<input>.txt
(Structure, u) ──internal forces──▶ N por barra  [a fazer]
```

`run_analysis(input)` em `Direct_Stiffness.jl` executa tudo e grava o relatório.

## Estrutura de arquivos

```
src/
├── Direct_Stiffness.jl          # módulo DirectStiffness; ÚNICO lugar com `include`
├── types/
│   ├── material_section.jl      # Material, AbstractSection, TrussSection, Frame_2D, Frame_3D, element_material
│   ├── geometry.jl              # AbstractGeom, GeomData2D/3D, element_geometry
│   ├── element.jl               # AbstractElement, Element{G,S}, ElementStiffness (não usado)
│   └── external_forces.jl       # build_F_vector
├── elements/truss.jl            # Truss2D/Truss3D (aliases) e seus métodos
├── assemble.jl                  # Structure, build_structure, K global, node_dofs
├── boundary.jl                  # build_displacement_vector
├── solver.jl                    # solve_system (partição)
├── report.jl                    # write_report (texto plano)
└── internal_forces.jl
```

Ordem dos `include` em `Direct_Stiffness.jl` importa para **tipos** (um `struct` precisa conhecer os tipos
dos campos). Funções podem ser definidas em qualquer ordem. Arquivos internos **não** dão `include` uns nos outros.

## Formato do TOML (`inputs/truss.toml`)

```toml
structure = "2d_truss"          # 2d_truss | 3d_truss | 2d_frame | 3d_frame

[materials]  steel = { E = ..., v = ... }
[sections]   sec_1 = { A = ... }          # pórtico exige Iz (2D) ou Ix,Iy,Iz,Jx,Jy,Jz (3D)

[mesh]
default_material = "steel"
default_section  = "sec_1"
nodes    = [[x, y], ...]                  # nó k = k-ésima linha (base 1)
elements = [[i, j], ...]                  # barra k = k-ésima linha
groups   = [ { elements = [4,5], material = "steel", section = "sec_1" } ]   # sobrescreve o padrão
boundary = [[nó, ux, uy], ...]            # 0.0 travado | nan livre | outro valor = recalque

[loads]                                   # NA RAIZ, não dentro de mesh
nodal_loads = [[nó, Fx, Fy], ...]         # eixos globais
```

Armadilha de TOML: tudo que vem depois de um cabeçalho `[tabela]` ou `[[tabela]]` pertence a ele.
Por isso `boundary` e `groups` ficam dentro de `mesh` (lidos como `mesh["boundary"]`, `mesh["groups"]`) e
`loads` fica na raiz (`data["loads"]`). Inline tables não aceitam quebra de linha.
`groups` é lista de inline tables (um por linha); grupos posteriores sobrescrevem anteriores.

## Decisões de projeto (e por quê)

### Modelo de tipos
- **`Element{G<:AbstractGeom, S<:AbstractSection}`** paramétrico, com campos `geometry`, `material`, `section`.
  Um só struct cobre todas as combinações; o tipo concreto sai da geometria (2D/3D) e da seção.
  Paramétrico (e não campos `::AbstractGeom`) para o compilador conhecer os tipos concretos e o despacho
  funcionar sem custo dinâmico.
- **Aliases em vez de um struct por elemento:** `const Truss2D = Element{GeomData2D, TrussSection}`,
  `const Truss3D = Element{GeomData3D, TrussSection}`. Struct próprio só quando um elemento tiver campo que
  os outros não têm (caso previsto: `Frame2D` com informação de rótulas).
- **O despacho múltiplo existe só em** `element_stiffness` e `transformation_matrix` (um método por alias).
  Todo o resto é agrupamento de dados. Regra adotada: *struct quando agrupa dados que andam juntos ou
  quando há métodos que despacham nele; senão, não criar*.
- **Não criar:** `AbstractMaterial` (só existe `Material`), `AbstractLoad` (cargas viram `F` e somem),
  struct embrulhando o vetor de deslocamentos, tipos-marca por estrutura (`Truss2DKind`), um struct por tipo
  de elemento.
- **`AbstractSection` e `AbstractGeom`** hoje só limitam o parâmetro de `Element`; passam a ter uso real
  com o pórtico.
- **Os nós da barra ficam em `GeomData`** (`geometry.nodes::Tuple{Int,Int}`), junto de `c, s, L` (2D) ou
  `l, m, n, L` (3D). Acesso uniforme: `e.geometry.nodes`.
- **`Structure{E<:Element}`** guarda `kind`, `dofs_per_node`, `nnodes`, `elements`. Cargas e apoios **não**
  ficam nele: servem só para montar `F` e `u_pre`. `kind` hoje só é usado em `dof_name`.

### Decidir por dicionário, não por `if`
`SECTION_PARSERS`, `DOFS_PER_NODE` e `DOF_NAMES` são `const Dict` indexados pelo `structure` do TOML.
Motivo: **organização** (um tipo novo de estrutura = uma entrada em cada tabela), não velocidade
(para 4 opções um `if` seria igual ou mais rápido, e esse código roda uma vez). Nomes desconhecidos dão
erro listando as opções válidas. Tipos-marca com despacho só compensariam se a decisão por estrutura
aparecesse em muitos arquivos.

### Geometria
`element_geometry(elem, nodes)` calcula por vetor: `d = nodes[j] - nodes[i]`, `L = norm(d)`, cossenos `d./L`.
A dimensão sai de `length(d)`. Erro explícito para barra de comprimento zero.
Conhecido: o retorno é `Union{GeomData2D, GeomData3D}` (instabilidade de tipo). Para malhas grandes, descobrir a
dimensão uma vez e passar `Val(dim)` (barreira de função).

### Numeração dos GDL
**Por nó**: `u1x, u1y, u2x, u2y, ...`. O nó `n` ocupa `node_dofs(n, d) = (n-1)*d+1 : n*d`, na ordem
`(ux, uy[, uz][, rotações])`. `d = DOFS_PER_NODE[kind]`: 2 (treliça 2D), 3 (treliça 3D e pórtico 2D), 6 (pórtico 3D).
Montagem, cargas e apoios **devem** usar `node_dofs`; qualquer divergência produz resultado errado sem aviso.
`dof_name(s, g)` converte GDL global em rótulo (`"u3x"`).
Numeração uniforme em todos os nós (não se numeram só os GDL com rigidez).

### Elemento e matrizes
- `element_stiffness(e)` devolve a matriz **já rotacionada para eixos globais** (4×4 treliça 2D, 6×6 treliça 3D),
  na ordem `[ux_i, uy_i, ux_j, uy_j]`. Nome a revisar quando entrar o pórtico (separar `stiffness_local` e `stiffness_global`).
- `transformation_matrix(e)` devolve a matriz 2×4 (ou 2×6) que leva deslocamentos globais para o eixo da barra;
  serve aos esforços internos, **não** à montagem.
- Contrato de um elemento: `element_stiffness`, `transformation_matrix`, `e.geometry.nodes`.

### Montagem
K global **esparsa por triplas** `(rows, cols, vals)` e `sparse(rows, cols, vals, n, n)`, que soma duplicatas
(é a soma da montagem). Evitado: `zeros(n,n)` (memória `n²`) e `spzeros` com atribuição por fatias (lento).
Termos nulos de `Ke` são armazenados (`dropzeros!` se necessário).

### Condições de contorno e cargas
- `u_pre`: vetor com `NaN` nos GDL livres, valor prescrito nos demais (0.0 = apoio, outro = recalque).
  Sempre derivar `fixed = findall(!isnan, u_pre)` e `free = findall(isnan, u_pre)` e indexar só por eles
  (`NaN` contamina qualquer conta que use o vetor inteiro).
- `F`: `zeros(n)`, cargas nodais **somadas** (`.+=`); `u_pre` usa `.=`.
- Validações: nó existente, número de valores igual a `d`, pelo menos um apoio. Chaves opcionais
  (`loads`, `nodal_loads`) usam `get(dict, chave, [])`; dados obrigatórios usam `dict[chave]`.
- Cargas de barra (`constant_loads`) estão previstas, mas só fazem sentido com pórtico. Quando entrarem:
  tabela de funções por tipo (`LOAD_APPLIERS`), não hierarquia de tipos.

### Solver (implementado em `solver.jl`)
**Partição** (eliminação dos GDL prescritos):

```julia
free, fixed = findall(isnan, u_pre), findall(!isnan, u_pre)
u = copy(u_pre)
u[free] = K[free, free] \ (F[free] - K[free, fixed] * u_pre[fixed])
R = K * u - F          # reações: usar R[fixed]
```

`\` do Julia já escolhe o método (LU/Cholesky/esparso); nunca usar `inv`. A alternativa "zeros e uns" com
`Diagonal(máscara)` também dá a mesma resposta, mas resolve o sistema inteiro. Resultado idêntico; a
diferença é custo e estilo. `SingularException` indica estrutura hipostática ou mecanismo.

### Esforços internos (planejado)
Por barra de treliça: `N = (E·A/L) · dot([-c, -s, c, s], u_e)`, positivo = tração, com
`u_e = u[idx]` e o mesmo `idx` da montagem. Extrair `element_dofs(e, d)` para montagem e esforços compartilharem.

### Pórtico e tirantes (planejado)
- Tirante num pórtico **não** é um tipo separado: é uma barra de pórtico com **rótulas nas duas pontas**.
  Condensando as duas rotações, a rigidez fica só com os termos axiais `EA/L` (igual à treliça).
- Implementar rótula por **condensação estática** no nível do elemento (campo de rótulas em `Frame2D`).
- Nó em que todas as barras são rotuladas fica sem rigidez de rotação (K singular): restringir essa rotação
  (ou não numerá-la). Momento na ponta rotulada é zero por construção.
- Verificar equilíbrio da barra (esforço axial) como checagem.
- `G = E / (2(1+v))` deve ser derivado de `Material(E, v)`; não criar `Material3DFrame`.

## Pendências e problemas conhecidos
1. `solve_system` detecta mecanismo pelo resíduo relativo `‖Kff·uf − rhs‖ ≤ 1e-8·‖rhs‖` (o Julia nem sempre lança
   `SingularException`: no teste com só o nó 1 apoiado, o resíduo foi 0.45; na estrutura estável, 3e-16).
   Se a carga for nula, a checagem não detecta mecanismo.
2. `src/internal_forces.jl` vazio.
3. Validar que a dimensão dos nós bate com `structure` (hoje `2d_truss` com nós 3D monta `Element{GeomData3D,...}` sem aviso).
4. `Material.v` e `G(E,v)` sem uso por enquanto; `ElementStiffness` definido e não usado.
5. Nome `ElementStiffness`/`element_stiffness` ambíguo entre local e global (revisar com o pórtico).
6. Sem testes automatizados. Sugestões: K de uma barra só; simetria e `K * [1,0,1,0,...] ≈ 0` (corpo rígido);
   comparar deslocamentos/esforços com solução analítica ou de referência para a treliça de exemplo.
7. Estabilidade de tipo em `element_geometry` (ver Geometria); alocações em `vcat`/`push!` na montagem — só
   medir (`BenchmarkTools`, `@code_warntype`) quando houver malha grande.

## Para o relatório
Pontos de discussão que têm justificativa registrada acima:
- por que treliça e pórtico compartilham `Element{G,S}` (despacho múltiplo e parâmetros de tipo);
- numeração de GDL por nó e montagem esparsa por triplas;
- tratamento de apoios e recalques por partição, com `NaN` como marcador de GDL livre;
- tirante como barra rotulada (condensação estática) em vez de elemento novo;
- verificação: conferência manual de termos de K, equilíbrio global (soma das reações = soma das cargas),
  comparação com solução de referência.
