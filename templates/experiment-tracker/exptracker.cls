\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{exptracker}[2026/09/28 v1.0 Experiment tracker report]

% Guidance notes are shown by default so a fresh copy of the template explains
% itself. The `final` option hides them and warns about unfilled placeholders.
\newif\ifet@final
\DeclareOption{final}{\et@finaltrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[11pt,a4paper]{article}

% ---------------------------------------------------------------------------
% Packages
% ---------------------------------------------------------------------------
\RequirePackage{iftex}
\ifPDFTeX
  \RequirePackage[T1]{fontenc}
  \RequirePackage{lmodern}
\else
  \RequirePackage{fontspec}
\fi
\RequirePackage[a4paper,margin=2.5cm,headheight=14pt]{geometry}
\RequirePackage{microtype}
\RequirePackage{xcolor}
\RequirePackage{graphicx}
\RequirePackage{booktabs}
\RequirePackage{tabularx}
\RequirePackage{amsmath,amssymb}
\RequirePackage{enumitem}
\RequirePackage{titlesec}
\RequirePackage{fancyhdr}
\RequirePackage{lastpage}
\RequirePackage[font=small,labelfont=bf]{caption}
\RequirePackage[round]{natbib}
\RequirePackage{parskip}
\RequirePackage[hyphens]{url}
\RequirePackage{hyperref}

% ---------------------------------------------------------------------------
% Colours
% ---------------------------------------------------------------------------
\definecolor{et@accent}{HTML}{1F3A5F}
\definecolor{et@muted}{HTML}{5F6B7A}
\definecolor{et@guidance}{HTML}{7A8594}
\definecolor{et@placeholder}{HTML}{8C97A3}
\definecolor{et@rule}{HTML}{C9D1DB}
\definecolor{et@grey}{HTML}{5F6B7A}
\definecolor{et@blue}{HTML}{2B6CB0}
\definecolor{et@amber}{HTML}{B7791F}
\definecolor{et@green}{HTML}{2F855A}
\definecolor{et@red}{HTML}{C53030}

\hypersetup{
  colorlinks=true,
  linkcolor=et@accent,
  citecolor=et@accent,
  urlcolor=et@blue,
}

% ---------------------------------------------------------------------------
% Headings and page style
% ---------------------------------------------------------------------------
\setcounter{secnumdepth}{0}
\titleformat{\section}{\sffamily\Large\bfseries\color{et@accent}}{}{0pt}{}
\titlespacing*{\section}{0pt}{1.4em plus 0.4em minus 0.2em}{0.3em}
\titleformat{\subsection}{\sffamily\large\bfseries\color{et@accent}}{}{0pt}{}
\titlespacing*{\subsection}{0pt}{1em plus 0.3em minus 0.1em}{0.2em}

\newcommand\et@footer{\small\sffamily\color{et@muted}\thepage\ of \pageref*{LastPage}}
\fancypagestyle{et@first}{%
  \fancyhf{}%
  \renewcommand\headrulewidth{0pt}%
  \fancyfoot[C]{\et@footer}}
\pagestyle{fancy}
\fancyhf{}
\renewcommand\headrulewidth{0pt}
\fancyhead[L]{\small\sffamily\color{et@muted}\@title}
\fancyfoot[C]{\et@footer}

% ---------------------------------------------------------------------------
% Tags: coloured labels for the report status and hypothesis verdicts. Known
% words get a colour; anything else is shown in grey.
% ---------------------------------------------------------------------------
\@namedef{et@tagcolour@Draft}{et@grey}
\@namedef{et@tagcolour@Proposed}{et@blue}
\@namedef{et@tagcolour@In progress}{et@amber}
\@namedef{et@tagcolour@Complete}{et@green}
\@namedef{et@tagcolour@Abandoned}{et@red}
\@namedef{et@tagcolour@Pending}{et@grey}
\@namedef{et@tagcolour@Supported}{et@green}
\@namedef{et@tagcolour@Partly supported}{et@amber}
\@namedef{et@tagcolour@Inconclusive}{et@amber}
\@namedef{et@tagcolour@Rejected}{et@red}

\newcommand\et@tag[1]{%
  \protected@edef\et@tagkey{#1}%
  \@ifundefined{et@tagcolour@\et@tagkey}%
    {\def\et@tagcolour{et@grey}}%
    {\edef\et@tagcolour{\csname et@tagcolour@\et@tagkey\endcsname}}%
  \edef\et@next{\noexpand\colorlet{et@tagcol}{\et@tagcolour}}\et@next
  {\setlength\fboxsep{2pt}%
   \colorbox{et@tagcol!12}{\textcolor{et@tagcol}{\sffamily\bfseries\footnotesize\et@tagkey}}}}

% \verdict{Supported}: Supported, Partly supported, Inconclusive, Rejected or
% Pending.
\newcommand\verdict[1]{\et@tag{#1}}

% ---------------------------------------------------------------------------
% Title block: title, then a metadata table of authors, date, version, status
% and related links.
% ---------------------------------------------------------------------------
\newcommand*\et@version{}
\newcommand*\et@status{}
\newcommand*\et@links{}
\newcommand*\version[1]{\gdef\et@version{#1}}
% \status{Draft}: Draft, Proposed, In progress, Complete or Abandoned.
\newcommand*\status[1]{\gdef\et@status{#1}}

% \relatedlink{label}{url}. The URL is read with & % # _ ~ ^ $ as ordinary
% characters, so links copied from W&B or Azure ML need no escaping.
\newcommand\relatedlink[1]{%
  \begingroup
  \@makeother\&\@makeother\%\@makeother\#\@makeother\_%
  \@makeother\~\@makeother\^\@makeother\$%
  \et@relatedlink{#1}}
\newcommand\et@relatedlink[2]{%
  \endgroup
  \ifx\et@links\@empty\else\g@addto@macro\et@links{\newline}\fi
  \g@addto@macro\et@links{\href{#2}{#1}}}

% \overleafproject{url}: the report's Overleaf project, shown as its own row.
% Leave the URL empty until the report is on Overleaf, and the row says so. The
% URL is read like \relatedlink's.
\newif\ifet@overleaf
\newcommand*\et@overleaf{}
\newcommand\overleafproject{%
  \begingroup
  \@makeother\&\@makeother\%\@makeother\#\@makeother\_%
  \@makeother\~\@makeother\^\@makeother\$%
  \et@overleafproject}
\newcommand\et@overleafproject[1]{%
  \endgroup
  \global\et@overleaftrue
  \gdef\et@overleaf{#1}}

\renewcommand\today{\number\day\space\ifcase\month\or
  January\or February\or March\or April\or May\or June\or July\or
  August\or September\or October\or November\or December\fi
  \space\number\year}

% Authors are joined with commas. The PDF metadata cannot \unskip the space
% before each \and, so it is removed from the token list first.
\pdfstringdefDisableCommands{\def\and{, }}
\ExplSyntaxOn
\cs_new_protected:Npn \et@setpdfinfo
  {
    \tl_set_eq:NN \l_tmpa_tl \@author
    \tl_replace_all:Nnn \l_tmpa_tl { ~ \and } { \and }
    \exp_args:Ne \hypersetup
      { pdftitle = { \exp_not:o \@title }, pdfauthor = { \exp_not:V \l_tmpa_tl } }
  }
\ExplSyntaxOff

\newcommand*\et@rows{}
\newcommand\et@addrow[2]{\g@addto@macro\et@rows{#1 & #2 \\}}

\renewcommand\maketitle{%
  \et@setpdfinfo
  \thispagestyle{et@first}%
  {\sffamily\bfseries\LARGE\color{et@accent}\@title\par}%
  \vspace{0.6em}%
  {\color{et@rule}\hrule height 0.5pt}%
  \vspace{0.5em}%
  \let\et@rows\@empty
  \et@addrow{Author(s)}{\@author}%
  \et@addrow{Date}{\@date}%
  \ifx\et@version\@empty\else\et@addrow{Version}{\et@version}\fi
  \ifx\et@status\@empty\else\et@addrow{Status}{\et@tag{\et@status}}\fi
  \ifet@overleaf
    \ifx\et@overleaf\@empty
      \et@addrow{Overleaf}{\textcolor{et@muted}{Not yet on Overleaf}}%
    \else
      \et@addrow{Overleaf}{\expandafter\url\expandafter{\et@overleaf}}%
    \fi
  \fi
  \ifx\et@links\@empty\else\et@addrow{Related links}{\et@links}\fi
  {\def\and{\unskip, }%
   \renewcommand\arraystretch{1.25}%
   \noindent
   \begin{tabularx}{\textwidth}{@{}>{\sffamily\small\color{et@muted}}l@{\hspace{2em}}X@{}}
     \et@rows
   \end{tabularx}\par}%
  \vspace{0.3em}%
  {\color{et@rule}\hrule height 0.5pt}%
  \vspace{0.4em}}

% ---------------------------------------------------------------------------
% Section content
% ---------------------------------------------------------------------------
% \guidance{...}: grey note under a heading saying what the section is for.
\newcommand\guidance[1]{%
  \ifet@final\else{\small\itshape\color{et@guidance}#1\par}\fi}

% \placeholder{...}: stand-in text to replace.
\newcommand\placeholder[1]{%
  \ifet@final\ClassWarning{exptracker}{Unfilled placeholder}\fi
  {\color{et@placeholder}[\,#1\,]}}

% \lead{Rationale}: starts a labelled paragraph inside an item.
\newcommand\lead[1]{\par\textit{#1:}\enspace}

% Numbered lists whose items get IDs (H1, A2, ...). \ref prints the ID, so
% later sections can point back at a hypothesis, assumption or finding.
\newcommand\et@idlist[2]{%
  \newlist{#1}{enumerate}{1}%
  \setlist[#1]{label=#2\arabic*, ref=#2\arabic*,
    font=\sffamily\bfseries\color{et@accent}, widest=00, leftmargin=*,
    align=left, itemsep=0.5em, parsep=0.25em, topsep=0.3em}}
\et@idlist{hypotheses}{H}
\et@idlist{assumptions}{A}
\et@idlist{approaches}{P}
\et@idlist{evidence}{E}
\et@idlist{criteria}{C}
\et@idlist{risks}{R}
\et@idlist{impacts}{I}
\et@idlist{findings}{F}

\setlist[itemize]{itemsep=0.2em, topsep=0.2em}
