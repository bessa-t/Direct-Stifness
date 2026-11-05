#import "lib.typ": *

#show: memoria-calculo.with(
  titulo: "Implementação do Método da Rigidez Direta",
  subtitulo: "Trabalho II",
  disciplina: "Teoria das Estruturas II",
  autores: ("Tarso de Matos Bessa",),
  matriculas: ("22/2013950",),
  professor: "",
  local: "Brasília, DF",
  data: "Novembro de 2026",
  logo: "assets/logo/unb.jpg",
)


= Introdução

O Método da Rigidez Direta é a base dos programas de análise estrutural. A estrutura é dividida em elementos unidimensionais, cada um com a sua matriz de rigidez. Essas matrizes são somadas em uma matriz global $K$, e o comportamento da estrutura passa a ser descrito por $K U = F$. Resolvido o sistema, obtêm-se as reações de apoio e os esforços internos de cada barra.

No Trabalho I, o método foi aplicado manualmente. Este trabalho implementa um programa que lê a descrição de uma estrutura em um arquivo de entrada e devolve deslocamentos, reações e esforços internos.

O escopo são treliças (planas e espaciais), vigas de Euler-Bernoulli e pórticos planos, com material elástico linear e pequenos deslocamentos. Cargas distribuídas uniformes são aceitas em vigas (barras horizontais) e em barras de pórtico de qualquer orientação, informadas em eixos globais. 

== Linguagem

O programa foi escrito em Julia, pelos seguintes motivos:

- sintaxe simples e código compilado com desempenho próximo ao de C;
- suporte nativo a matrizes, a matrizes esparsas e à resolução de sistemas lineares (operador `\`);
- índices começando em 1, de modo que o número do nó ou do grau de liberdade coincide com a sua posição nas matrizes, como nas deduções manuais.

Usam-se apenas bibliotecas padrão: `LinearAlgebra`, `SparseArrays`, `TOML` (leitura da entrada) e `Printf` (relatório).

= Arquitetura do Software

O programa é um único módulo Julia, `DirectStiffness`, dividido em arquivos pequenos, cada um responsável por uma etapa da análise. Os dados de entrada ficam em arquivos TOML, e os resultados são gravados em arquivos de texto. O código-fonte está disponível em #link("https://github.com/bessa-t/Direct-Stifness").

== Organização do diretório

#figure(
  kind: image,
  supplement: [Figura],
  align(left, block(
    fill: luma(247),
    stroke: 0.5pt + luma(200),
    inset: 10pt,
    radius: 3pt,
    ```
    Direct-Stifness/
    ├── inputs/                      arquivos de entrada (TOML)
    │   ├── 2d_truss.toml
    │   ├── 2d_beam.toml
    │   ├── 2d_frame.toml
    │   └── ...
    ├── outputs/                     relatórios gerados (.txt)
    ├── relatorio/                   este documento (Typst)
    └── src/
        ├── Direct_Stiffness.jl      módulo; único arquivo com include
        ├── input.jl                 leitura do TOML e montagem da estrutura
        ├── assemble.jl              Structure e matriz de rigidez global
        ├── boundary.jl              vetor de deslocamentos prescritos
        ├── external_forces.jl       vetor de forças e cargas equivalentes
        ├── solver.jl                solução do sistema por partição
        ├── internal_forces.jl       esforços internos por barra
        ├── report.jl                relatório em texto
        ├── test.jl                  roda o exemplo e imprime na tela
        ├── types/
        │   ├── material_section.jl  material e seções
        │   ├── geometry.jl          comprimento e cossenos diretores
        │   └── element.jl           tipo Element e GDL do elemento
        └── elements/
            ├── truss.jl             treliça
            ├── bernoulli_beam.jl    viga de Euler-Bernoulli
            └── frame.jl             pórtico plano
    ```,
  )),
  caption: [Organização dos arquivos do projeto.],
)

Os arquivos seguem três critérios:

- *Tipos de dados* (`types/`): definem os tipos usados no programa (material, seção, geometria, elemento) e não contêm lógica de análise.
- *Elementos* (`elements/`): um arquivo por tipo de elemento estrutural, com a sua matriz de rigidez e a sua matriz de transformação, com exceção ao elemento de viga, que é dado como sempre horizontal.
- *Etapas da análise* (raiz de `src/`): um arquivo por etapa do processamento, na ordem em que acontecem (leitura, com apoios e cargas; montagem; solução; esforços; relatório).

Só o arquivo `Direct_Stiffness.jl` faz `include` dos demais. 

== Fluxo da entrada de dados

A leitura do arquivo TOML está concentrada em `input.jl`: é o único arquivo que conhece os nomes das chaves e o formato das linhas. Todo o restante do programa recebe dados já validados, na forma de estruturas e vetores. A função `load_model` devolve a estrutura `s`, o vetor de deslocamentos prescritos `u_pre`, o vetor de forças `F`, as suas parcelas `f_vec` (cargas nodais) e `f_dist` (cargas distribuídas) e a carga distribuída de cada barra, `element_q`.

#let caixa(corpo, fundo: rgb("#e8eef6")) = rect(
  fill: fundo,
  stroke: 0.6pt + rgb("#003366"),
  radius: 3pt,
  inset: 6pt,
  width: 100%,
  align(center, corpo),
)
#let seta = align(center, text(size: 13pt, fill: rgb("#003366"), $arrow.b$))

#figure(
  kind: image,
  supplement: [Figura],
  block(width: 100%, {
    set text(size: 9pt)
    caixa[Arquivo TOML \ `inputs/*.toml`]
    seta
    caixa[`TOML.parsefile` \ dicionário com `structure`, `materials`, `sections`, `mesh`, `loads`]
    v(2pt)
    grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 8pt,
      row-gutter: 3pt,
      caixa(fundo: rgb("#f2f2f2"))[`mesh`: nós, barras, \ materiais e seções],
      caixa(fundo: rgb("#f2f2f2"))[`mesh["boundary"]` \ (apoios e recalques)],
      caixa(fundo: rgb("#f2f2f2"))[`loads`: cargas nodais \ e distribuídas],
      seta, seta, seta,
      caixa[`build_structure` \ `parse_nodes`, `parse_connectivity`, `assign_properties`, `element_geometry`],
      caixa[`parse_nodal_rows` \ `build_displacement_vector`],
      caixa[`parse_nodal_rows`, `parse_constant_loads` \ `build_F_vector`],
      seta, seta, seta,
      caixa(fundo: rgb("#dcebdc"))[`s::Structure` \ nós e barras],
      caixa(fundo: rgb("#dcebdc"))[`u_pre` \ `NaN` = GDL livre],
      caixa(fundo: rgb("#dcebdc"))[`F` e `element_q` \ forças nodais totais],
    )
    seta
    caixa[`load_model` devolve `(s, u_pre, F, f_vec, f_dist, element_q)`]
  }),
  caption: [Fluxograma da entrada de dados.],
) <fig-entrada>

Cada ramo do fluxograma valida o que lê: existência dos nós citados, número de valores por nó compatível com os graus de liberdade, barras com dois nós existentes e existência de pelo menos um apoio. Erros de entrada interrompem a execução com uma mensagem indicando o que está errado.

== Fluxo de Execução

A análise completa é executada pela função `run_analysis`, definida em `Direct_Stiffness.jl`. Ela encadeia as cinco etapas do método, cada uma implementada em um arquivo próprio, e grava o relatório em `outputs/<nome do arquivo de entrada>.txt`. 

#figure(
  kind: image,
  supplement: [Figura],
  block(width: 70%, {
    set text(size: 9pt)
    caixa[*1. Leitura* (`input.jl`) \ `load_model` \ devolve `s`, `u_pre`, `F`, `f_vec`, `f_dist`, `element_q`]
    seta
    caixa[*2. Montagem* (`assemble.jl`) \ `build_global_stiffness_matrix(s)` \ devolve `K` (esparsa)]
    seta
    caixa[*3. Solução* (`solver.jl`) \ `solve_system(K, F, u_pre)` \ devolve `u` e `R`]
    seta
    caixa[*4. Esforços internos* (`internal_forces.jl`) \ `element_internal_forces(s, u, element_q)` \ devolve esforços por barra]
    seta
    caixa[*5. Relatório* (`report.jl`) \ `write_report(...)` \ grava `outputs/<entrada>.txt`]
  }),
  caption: [Fluxo de execução do programa.],
)

*1. Leitura.* O arquivo TOML é convertido em uma estrutura `Structure`, no vetor de deslocamentos prescritos `u_pre` e no vetor de forças `F` (@fig-entrada). Os apoios e as cargas só servem para montar esses vetores, e depois deixam de existir como objetos.

*2. Montagem.* Cada barra calcula a sua matriz de rigidez já em eixos globais, e esta é somada na posição dos seus graus de liberdade na matriz global esparsa `K`.

*3. Solução.* Os graus de liberdade prescritos são eliminados do sistema, e resolve-se $K_(l l) U_l = F_l - K_(l p) U_p$ apenas para os graus de liberdade livres, em que $l$ indica livre e $p$ prescrito. Em seguida, as reações são obtidas por $R = K U - F$, tomadas nos graus de liberdade prescritos.

*4. Esforços internos.* Para cada barra, os deslocamentos dos seus nós são lidos do vetor global `u`. Eles são levados para os eixos locais da barra, e deles saem o esforço normal, o cortante e o momento fletor.

*5. Relatório.* Modelo, cargas, deslocamentos prescritos, deslocamentos nodais, reações e esforços internos são escritos em texto plano.

O programa pode ser executado pelo seguinte comando, sendo o segundo argumento o endereço do arquivo de input a partir da raíz do diretório:

```bash
julia src/Direct_Stiffness.jl inputs/2d_frame.toml

```


= Decisões de Projeto e Implementação



#let codigo(corpo) = block(
  fill: luma(247),
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  radius: 3pt,
  width: 100%,
  breakable: false,
  text(size: 8.5pt, corpo),
)

== Definição e Leitura da Entrada de Dados

Escolheu-se o formato TOML porque é fácil de ler e de escrever, tem leitor nativo em Julia e dispensa um analisador próprio: `TOML.parsefile` devolve diretamente um dicionário. O exemplo abaixo descreve o pórtico do Exercício IV.

#codigo[
```toml
structure = "2d_frame"

[materials]
steel = { E = 180e6, v = 0.3 }          # E [kN/m2]

[sections]
sec_1 = { A = 5.0e-3, Iz = 2.1e-6 }     # A [m2], Iz [m4]

[mesh]
default_material = "steel"
default_section = "sec_1"
nodes = [[0.0, 0.0], [0.0, 2.0], [2.0, 2.0], [2.0, 0.0]]
elements = [[1, 2], [2, 3], [3, 4]]     # nó i, nó j
boundary = [
    [1, 0.0, 0.0, 0.0],                 # nó, ux, uy, θ (nan = livre)
    [4, 0.0, 0.0, 0.0],
]

[loads]
constant_loads = [[2, 0.0, -0.5]]       # elemento, qx, qy [kN/m]
```
]

Nós e barras são numerados pela ordem das linhas. O tipo de estrutura (`structure`) escolhe, em tabelas de consulta, quantos graus de liberdade (GDL) cada nó tem e como a seção é lida.  O arquivo `input.jl` converte o dicionário nas estruturas e vetores usados pelo restante do programa.

== Estratégia de Montagem da Rigidez Global

Os GDL são numerados por nó: o nó $n$ ocupa as posições $(n-1) d + 1$ a $n d$, em que $d$ é o número de GDL por nó (2 na treliça plana e na viga, 3 na treliça espacial e no pórtico plano). Cada elemento calcula a sua matriz de rigidez já em eixos globais, e a matriz global é montada de forma esparsa, por triplas (linha, coluna, valor):

#codigo[
```julia
function build_global_stiffness_matrix(s::Structure)
    d = s.dofs_per_node             # GDL por nó
    n = nnodes(s) * d               # tamanho da matriz

    rows = Int[]; cols = Int[]; vals = Float64[]

    for e in s.elements
        idx = element_dofs(e, d)    # GDL globais do elemento
        Ke  = element_stiffness(e)  # rigidez em eixos globais

        for b in eachindex(idx), a in eachindex(idx)
            push!(rows, idx[a])     # linha global
            push!(cols, idx[b])     # coluna global
            push!(vals, Ke[a, b])   # valor
        end
    end

    return sparse(rows, cols, vals, n, n)   # posições repetidas são somadas
end
```
]

A função `sparse` soma os valores de posições repetidas, que é exatamente a soma da montagem. Assim, evita-se alocar uma matriz densa $n times n$, cuja memória cresce com o quadrado do número de GDL.

== Tipos Concretos e Desempenho

Todos os `struct` do programa têm campos com tipo concreto: `Float64` para propriedades e coordenadas, `Int` para números de nós, `Tuple{Int,Int}` para os nós de uma barra e `Vector{Vector{Float64}}` para as coordenadas da estrutura. O elemento (`Element{G,S}`) e a estrutura (`Structure{E}`) são paramétricos, de modo que o compilador conhece os tipos exatos de cada elemento, e o despacho de `element_stiffness` e `transformation_matrix` é resolvido na compilação. Assim o Julia gera código de máquina específico para cada tipo, sem verificações de tipo em tempo de execução.

Essa escolha foi feita pensando em desempenho, mas nenhuma medição de tempo foi realizada, pois os exemplos são pequenos. Duas exceções conhecidas poderiam ser revistas: `element_geometry` devolve `GeomData2D` ou `GeomData3D` conforme a dimensão dos nós (tipo de retorno não fixo), e a montagem acumula as triplas com `push!`, sem alocar os vetores com antecedência.

== Estrutura do Elemento

`Element{G,S}` guarda a geometria (`G`), o material e a seção (`S`) de uma barra. A geometria é `GeomData2D` ou `GeomData3D`, conforme a dimensão dos nós, e já traz pronto o que a rigidez e a transformação precisam (nós, cossenos diretores, comprimento):

#codigo[
```julia
struct Element{G<:AbstractGeom, S<:AbstractSection}
    geometry :: G
    material :: Material
    section  :: S
end

struct GeomData2D <: AbstractGeom
    nodes::Tuple{Int,Int}
    c::Float64   # cosseno diretor
    s::Float64   # seno diretor
    L::Float64   # comprimento
end
```
]

Cada tipo de elemento é só um alias de `Element` fixando `G` e `S`, o que dá despacho estático: o pórtico plano (`Frame_2D`) usa `GeomData2D` e `Frame_2D_Section` (A e $I_z$):

#codigo[
```julia
const Frame_2D = Element{GeomData2D, Frame_2D_Section}

function element_stiffness(e::Frame_2D)
    E, A, L, I = e.material.E, e.section.A, e.geometry.L, e.section.Iz
    ...
end
```
]

== Tratamento das Condições de Contorno e Carregamentos

Apoios e cargas são lidos do TOML e viram dois vetores com um valor por GDL: `u_pre` (deslocamentos prescritos) e `F` (forças). A tabela resume o formato de cada dado no pórtico plano. Nos demais elementos, apoios e cargas nodais têm um valor para cada GDL do nó:

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header[Dado][Linha no TOML][Efeito],
    [Apoio ou recalque], [`[nó, ux, uy, θ]`], [Preenche `u_pre`: valor prescrito (0 = apoio) ou `nan` (GDL livre)],
    [Carga nodal], [`[nó, Fx, Fy, M]`], [Somada em `F`, nos GDL do nó],
    [Carga distribuída], [`[elemento, qx, qy]`], [Forças nodais equivalentes, somadas em `F`],
  ),
  caption: [Formato dos apoios e das cargas.],
)

=== Condições de contorno

Um apoio que trava só em $y$ no nó 1 é escrito `[1, nan, 0.0]`, e um recalque é um valor diferente de zero. Os índices de GDL livres e prescritos saem de `findall(isnan, u_pre)` e `findall(!isnan, u_pre)`.

=== Cargas nodais

As forças e momentos aplicados diretamente nos nós são somados em `F` nos GDL do nó (`F[node_dofs(nó, d)] .+= valores`).

=== Cargas distribuídas

As linhas `[elemento, qx, qy]` dão uma carga uniforme por comprimento de barra, em eixos globais. Ela é convertida em forças nodais equivalentes pela função `equivalent_nodal_loads`, que tem um método para cada elemento.

*Viga.* Como é horizontal e não tem GDL axial, basta o vetor de engastamento perfeito:

#codigo[
```julia
function equivalent_nodal_loads(e::Beam, qx, qy)
    L = e.geometry.L
    return [qy*L/2, qy*L^2/12, qy*L/2, -qy*L^2/12]
end
```
]

*Pórtico.* A carga é decomposta nas componentes ao longo da barra ($q_a$) e perpendicular a ela ($q_t$). As forças equivalentes são calculadas nos eixos locais e levadas aos eixos globais com a transposta da matriz de transformação, a mesma usada na montagem:

#codigo[
```julia
function local_load(e, qx, qy)
    c, s = e.geometry.c, e.geometry.s
    return (qa = c*qx + s*qy, qt = -s*qx + c*qy)
end

function equivalent_nodal_loads(e::Frame_2D, qx, qy)
    L = e.geometry.L
    qa, qt = local_load(e, qx, qy)
    f_local = [qa*L/2, qt*L/2, qt*L^2/12, qa*L/2, qt*L/2, -qt*L^2/12]
    return transformation_matrix(e)' * f_local    # eixos globais
end
```
]

O resultado é somado em `F`. Como a reação é calculada por $R = K U - F$, as cargas distribuídas não precisam de tratamento separado.

== Resolução do Sistema

Reordenando os GDL em livres ($l$) e prescritos ($p$), o sistema fica:

$ mat(K_(l l), K_(l p); K_(p l), K_(p p)) vec(U_l, U_p) = vec(F_l, F_p + R_p) $

Como $U_p$ é conhecido, os deslocamentos livres saem de

$ K_(l l) U_l = F_l - K_(l p) U_p $

No código, `free` e `prescribed` guardam os índices obtidos por `findall`, `rhs` é o lado direito, e o operador `\` do Julia escolhe o método de solução. 

#codigo[
```julia
function solve_system(K, F, u_pre)
    free       = findall(isnan, u_pre)
    prescribed = findall(!isnan, u_pre)

    Kff = K[free, free]
    rhs = F[free] - K[free, prescribed] * u_pre[prescribed]

    uf = Kff \ rhs

    u = copy(u_pre)
    u[free] = uf

    R = K * u - F          # reações: R[prescribed]
    return u, R
end
```
]

Com todos os deslocamentos conhecidos, $R = K U - F$ vale zero nos GDL livres (equilíbrio) e dá a reação de apoio nos GDL prescritos. Nesses GDL, $F$ contém apenas as cargas conhecidas ($F_p$), como as forças equivalentes de uma carga distribuída em barra ligada ao apoio, e a subtração deixa só a reação $R_p$.


== Cálculo dos Esforços Internos

Depois de resolvido o sistema, os esforços de cada barra saem dos deslocamentos dos seus nós, lidos do vetor global: `u_e = u[element_dofs(e, d)]`. Na treliça e no pórtico, $u_e$ é levado aos eixos locais da barra por $u_"loc" = T u_e$. Cada tipo de elemento tem a sua função `get_internal_forces`, e o resultado é um conjunto de valores nomeados que o relatório imprime sem precisar conhecer o elemento.

#figure(
  table(
    columns: 2,
    align: (left, left),
    table.header[Elemento][Esforços (eixos locais)],
    [Treliça], [$N$],
    [Viga], [$V_i$, $V_j$, $M_i$, $M_j$],
    [Pórtico plano], [$N_i$, $N_j$, $V_i$, $V_j$, $M_i$, $M_j$],
  ),
  caption: [Esforços calculados por elemento.],
)

*Esforço normal.* É calculado como na treliça, $N = E A / L (u_j - u_i)$ com $u$ nos eixos locais, positivo em tração. Se houver carga ao longo da barra ($q_a$), $N$ varia linearmente e esse valor é o da média: $N_i = N + q_a L / 2$ e $N_j = N - q_a L / 2$.

*Flexão.* Na viga e no pórtico, integra-se a equação da linha elástica, $E I v'''' = q_t$, com $q_t$ a carga uniforme perpendicular à barra. Adotando $V = E I v'''$ e $M = E I v''$:

$ V(x) = q_t x + c_1, quad M(x) = (q_t x^2)/2 + c_1 x + c_2 $

$ E I v'(x) = (q_t x^3)/6 + (c_1 x^2)/2 + c_2 x + c_3, quad E I v(x) = (q_t x^4)/24 + (c_1 x^3)/6 + (c_2 x^2)/2 + c_3 x + c_4 $

As quatro constantes de integração ($c_1$ a $c_4$) são obtidas da equação abaixo, implementada na função `integration_constants`. Ela usa os deslocamentos locais das extremidades da barra, $v$ (transversal) e $theta$ (rotação):

$
  vec(c_1, c_2, c_3, c_4) =
  mat(
    (12 E I)/L^3, (6 E I)/L^2, -(12 E I)/L^3, (6 E I)/L^2;
    -(6 E I)/L^2, -(4 E I)/L, (6 E I)/L^2, -(2 E I)/L;
    0, E I, 0, 0;
    E I, 0, 0, 0
  )
  vec(
    v_i,
    theta_i,
    v_j - (q_t L^4)/(24 E I),
    theta_j - (q_t L^3)/(6 E I)
  )
$

= Validação dos Modelos Estruturais

Os resultados do programa foram comparados com os do Trabalho I e, no pórtico, com o Ftool. Os relatórios abaixo são os arquivos gerados em `outputs/`, sem edição.

#let relatorio-txt(path, legenda) = figure(
  kind: image,
  supplement: [Figura],
  block(
    fill: luma(247),
    stroke: 0.5pt + luma(200),
    inset: 8pt,
    radius: 3pt,
    width: 100%,
    breakable: true,
    text(size: 6.5pt, raw(read(path), block: true)),
  ),
  caption: legenda,
)
#show figure: set block(breakable: true)
#show figure.where(kind: table): set block(breakable: false)

== Treliça Bidimensional

Entrada: `inputs/2d_truss_trabalho1.toml` (dados do Exercício I, em kN e m).

#relatorio-txt("/outputs/2d_truss_trabalho1.txt")[Relatório do programa para a treliça plana.]

Os deslocamentos e os esforços normais coincidem com o Trabalho I:

#figure(
  table(
    columns: 5,
    align: center + horizon,
    table.header[GDL][Trabalho I \ ($times 10^(-3)$ mm)][Programa \ ($times 10^(-3)$ mm)][Barra][N (kN)\ Trabalho I = Programa],
    [$u_(2x)$], [5.556], [5.556], [1], [+2.5],
    [$u_(2y)$], [−6.415], [−6.415], [2], [−2.5],
    [$u_(4x)$], [30.556], [30.556], [3], [+5.0],
    [$u_(4y)$], [−4.811], [−4.811], [4], [−5.0],
    [$u_(5x)$], [19.444], [19.444], [5], [+5.0],
    [$u_(5y)$], [−1.604], [−1.604], [6 e 7], [−5.0],
  ),
  caption: [Treliça plana: Trabalho I × programa.],
)



== Treliça Espacial

Entrada: `inputs/3d_truss.toml` (Exercício II).

#relatorio-txt("/outputs/3d_truss.txt")[Relatório do programa para a treliça espacial.]

#figure(
  table(
    columns: 4,
    align: center + horizon,
    table.header[Grandeza][Trabalho I][Programa][Unidade],
    [$u_(1x)$], [−0.13], [−0.130], [mm],
    [$u_(1y)$], [0.205], [0.205], [mm],
    [$u_(1z)$], [0.05], [0.050], [mm],
    [$N_1$], [+15], [+15.000], [kN],
    [$N_2$], [−18.014], [−18.028], [kN],
    [$N_3$], [0], [0.000], [kN],
  ),
  caption: [Treliça espacial: Trabalho I × programa.],
)

A única diferença está na barra 2 (−18.014 contra −18.028 kN) e vem do arredondamento do Trabalho I . 

== Viga de Euler-Bernoulli

Entrada: `inputs/2d_beam.toml` (Exercício III, viga biengastada com $q$, $P$ e $M$).

#relatorio-txt("/outputs/2d_beam.txt")[Relatório do programa para a viga.]

#figure(
  table(
    columns: 4,
    align: center + horizon,
    table.header[Grandeza][Analítico \ (Trabalho I)][Rigidez direta \ (Trabalho I)][Programa],
    [$V_a$ (kN)], [5.286], [5.286], [5.286],
    [$M_a$ (kN·m)], [8.619], [8.619], [8.619],
    [$V_d$ (kN)], [5.714], [5.714], [5.714],
    [$M_d$ (kN·m)], [−9.617], [−9.619], [−9.619],
    [$v(x = 2)$ (mm)], [−27.841], [−27.84], [−27.841],
    [$v(x = 4)$ (mm)], [−46.484], [−46.485], [−46.485],
  ),
  caption: [Viga: Trabalho I × programa.],
)

O programa reproduz o resultado da rigidez direta do Trabalho I. A diferença de 0.002 kN·m para o resultado analítico em $M_d$ vem de arredondamento no cálculo analítico.

== Pórtico Bidimensional

Entrada: `inputs/2d_frame.toml` (Exercício IV).

#relatorio-txt("/outputs/2d_frame.txt")[Relatório do programa para o pórtico plano.]

Na comparação com o Trabalho I houve divergência. Após uma análise mais criteriosa, concluiu-se que o erro estava no Trabalho I, que adotou $theta = 90°$ para a barra 3. Como a barra 3 vai do nó 3 (topo) ao nó 4 (base), o ângulo correto é $-90°$. Com a matriz do elemento 3 corrigida, os resultados do Trabalho I passam a coincidir com os do programa. Como verificação independente, a estrutura foi modelada no Ftool:

#figure(
  image("assets/image.png", width: 55%),
  caption: [Pórtico no Ftool: momento fletor e reações.],
)

#figure(
  table(
    columns: 3,
    align: center + horizon,
    table.header[Grandeza][Programa][Ftool],
    [$R_(1x)$ (kN)], [0.083], [0.083],
    [$R_(1y)$ (kN)], [0.500], [0.500],
    [$R_(1theta)$ (kN·m)], [−0.056], [0.056],
    [$M$ no topo da coluna (kN·m)], [0.111], [0.111],
    [$M$ no meio do vão (kN·m)], [0.139], [0.139],
  ),
  caption: [Pórtico: programa × Ftool. Os sinais seguem a convenção de cada programa, e o momento no meio do vão foi obtido de $V_i$ e $M_i$ do relatório.],
)


= Melhorias Futuras

#block(breakable: false)[
Para tornar o programa mais robusto, poderiam ser implementados:

- testes automatizados;
- visualização gráfica dos resultados;
- elementos de pórtico tridimensional;
- rótulas internas;
- cargas trapezoidais;
- elementos de casca (_shell_), para analisar estruturas mais gerais.
]

Há também uma limitação de projeto. O elemento guarda apenas os índices de dois nós, e os GDL são deduzidos do tipo de estrutura. Por isso o programa não analisa estruturas com mais de um tipo de elemento, como pórticos atirantados, nem elementos com mais de dois nós, como barras curvas. Para incluir estas melhorias, o elemento deveria guardar a lista dos seus nós e dos respectivos GDL, e a montagem passaria a percorrer essa lista.

= Conclusão

Implementou-se, em Julia, um programa de análise pelo Método da Rigidez Direta para treliças, vigas, pórticos planos e treliças espaciais. Ele lê a estrutura de um arquivo TOML, monta a matriz global de forma esparsa, trata apoios, recalques e cargas distribuídas, e devolve deslocamentos, reações e esforços internos em um relatório de texto.

Os resultados coincidem com os do Trabalho I nas treliças e na viga e com o Ftool no pórtico. A comparação também apontou um erro no Trabalho I, na matriz da barra 3 do pórtico. O programa, entre outras funcionalidades, substitui a montagem manual das matrizes, que era a etapa mais sujeita a erros no Trabalho I.
