#let azul-unb = rgb("#003366")

#let _authors-with-registration(autores, matriculas) = {
  if autores == none or autores.len() == 0 {
    none
  } else {
    autores.enumerate().map(((idx, autor)) => {
      let matricula = if matriculas != none and idx < matriculas.len() and matriculas.at(idx) != "" {
        matriculas.at(idx)
      } else {
        "__________"
      }
      [#autor (#matricula)]
    }).join([#linebreak()])
  }
}

#let _authors-block(autores, matriculas) = {
  let autores-texto = _authors-with-registration(autores, matriculas)
  if autores-texto == none {
    none
  } else {
    set par(justify: false, first-line-indent: 0pt)
    align(right)[#autores-texto]
  }
}

#let _place-and-date(local, data) = {
  if local != none and local != "" and data != none and data != "" {
    [#local #linebreak() #data]
  } else if local != none and local != "" {
    [#local]
  } else if data != none and data != "" {
    [#data]
  }
}

#let _title-page(
  titulo,
  subtitulo,
  instituicao,
  faculdade,
  departamento,
  disciplina,
  autores,
  matriculas,
  professor,
  local,
  data,
  logo,
) = {
  align(center)[
    #if logo != none and logo != "" {
      image(logo, width: 48mm)
      v(8mm)
    }

    #text(weight: "bold", size: 12pt)[#instituicao]
    #linebreak()
    #faculdade
    #linebreak()
    #departamento

    #v(35mm)

    #text(fill: azul-unb, weight: "bold", size: 18pt)[#titulo]
    #if subtitulo != none and subtitulo != "" {
      [#linebreak()#text(size: 13pt)[#subtitulo]]
    }
    #if disciplina != none and disciplina != "" {
      v(10mm)
      text(size: 12pt)[Disciplina: #disciplina]
    }
    #if professor != none and professor != "" {
      linebreak()
      text(size: 12pt)[#professor]
    }

    #v(1fr)

    #align(right)[#_authors-block(autores, matriculas)]

    #v(6mm)

    #_place-and-date(local, data)
  ]
  pagebreak()
}

#let memoria-calculo(
  titulo: "Título do Trabalho",
  subtitulo: none,
  instituicao: "Universidade de Brasília",
  faculdade: "Faculdade de Tecnologia",
  departamento: "Departamento de Engenharia Civil e Ambiental",
  disciplina: none,
  autores: (),
  matriculas: (),
  professor: none,
  local: "Brasília, DF",
  data: "",
  logo: none,
  corpo: true,
  body,
) = {
  set document(
    title: titulo,
    author: autores,
  )

  set text(
    font: "New Computer Modern",
    size: 12pt,
    lang: "pt",
    region: "BR",
  )
  set par(
    justify: true,
    leading: 0.5em,
    first-line-indent: (amount: 1.25cm, all: true),
  )
  set heading(numbering: "1.1.")
  set table(
    stroke: 0.5pt + azul-unb,
    fill: none,
    inset: (x: 6pt, y: 5pt),
  )
  show table: it => {
    v(0.75em)
    align(center)[#it]
    v(0.75em)
  }
  show table.cell.where(y: 0): it => {
    set text(weight: "bold")
    it
  }
  show table.cell: it => {
    set par(justify: false, first-line-indent: 0pt)
    set text(hyphenate: false)
    it
  }
  show figure: it => {
    v(1em)
    it
    v(1em)
  }
  show heading: it => {
    v(1em)
    text(fill: azul-unb, weight: "bold")[#it]
    v(0.5em)
  }
  set list(
    indent: 1.25cm,
    marker: ([•], [‣], [–]).map(m => text(fill: azul-unb)[#m]),
  )
  set enum(
    indent: 1.25cm,
    numbering: (..n) => text(fill: azul-unb)[#numbering("1.", n.pos().last())],
  )
  show list: set par(first-line-indent: 0pt)
  show enum: set par(first-line-indent: 0pt)
  show link: underline

  let corpo-iniciado = state("memoria-calculo-corpo-iniciado", false)
  set page(
    paper: "a4",
    margin: (top: 30mm, bottom: 20mm, left: 30mm, right: 20mm),
    numbering: none,
    header: context {
      if corpo-iniciado.get() {
        set text(size: 8pt)
        grid(
          columns: (1fr, auto),
          gutter: 6pt,
          [#titulo],
          [Página #counter(page).display()],
        )
        line(length: 100%, stroke: 0.4pt + gray)
      }
    },
    footer: context {
      if corpo-iniciado.get() {
        set text(size: 8pt)
        align(center)[#instituicao -- #departamento]
      }
    },
  )

  _title-page(
    titulo,
    subtitulo,
    instituicao,
    faculdade,
    departamento,
    disciplina,
    autores,
    matriculas,
    professor,
    local,
    data,
    logo,
  )

  if corpo {
    outline(title: text(fill: azul-unb, weight: "bold")[Sumário], indent: auto)
    counter(page).update(0)
    corpo-iniciado.update(true)
    pagebreak()
  } else {
    corpo-iniciado.update(true)
  }

  body
}
