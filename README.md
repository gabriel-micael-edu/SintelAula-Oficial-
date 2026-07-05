# SintelAula 🎓🏫

O **SintelAula** é um ecossistema inteligente e offline de gerenciamento escolar projetado para simplificar e otimizar as rotinas pedagógicas e administrativas de professores e gestores escolares. O sistema opera de forma totalmente local, integrando Inteligência Artificial (IA) local, ferramentas avançadas de apresentação, elaboração de planos de aula e um controle completo de turmas, alunos, frequência e avaliações.

Este repositório contém todo o código-fonte da solução, estruturado de forma profissional e automatizada.

---

## 📸 Demonstração Visual

Abaixo estão alguns dos painéis e designs do SintelAula que ilustram a interface visual moderna e intuitiva:

*   **Painel Principal (Modo Escuro / Claro)**: Centraliza as principais ferramentas e atalhos de navegação.
*   **Controle de Alunos e Turmas**: Cadastro e visualização rápida dos dados da turma.
*   **Ferramentas Úteis**: Recursos de produtividade e IA integrados diretamente ao fluxo pedagógico.

> [!NOTE]
> As capturas de tela e mockups oficiais da interface estão organizados na pasta `assets/screenshots/` e podem ser visualizados diretamente no repositório.

---

## 🛠️ Arquitetura do Projeto

A solução foi desenvolvida utilizando a plataforma **.NET 10** e a interface gráfica moderna **WinUI 3** via **Windows App SDK 1.7**. O código é dividido de forma modular nos seguintes projetos:

```
C:\Programa_SintelAula\Colocar github\
├── SintelAula.sln             # Solução do Visual Studio (centraliza todos os projetos)
├── build.ps1                  # Script de compilação automatizada
├── build_msix_store.ps1       # Script de geração do pacote MSIX oficial
├── publish_and_update.ps1     # Script de publicação e atualização rápida
├── global.json                # Configuração do .NET SDK 10.x
├── src/                       # Diretório contendo os códigos-fontes
│   ├── SintelAula.App/        # Core da aplicação principal (gerenciamento escolar)
│   ├── SintelAula.Installer/  # Instalador visual e assistente de configuração (.exe independente)
│   ├── SintelAula.Package/    # Configurações e manifesto do empacotamento MSIX
│   └── MinhaEscolaWinUI/      # Módulo/API de sincronização escolar complementar
└── assets/                    # Recursos multimídia e documentação
    ├── screenshots/           # Capturas de tela (PNG)
    ├── logos/                 # Ícones, logotipos da Líbera EdTech e SintelAula
    └── docs/                  # Manuais, relatórios e documentação técnica em PDF
```

---

## 🚀 Como Compilar e Executar o SintelAula

### Pré-requisitos
1.  **Windows 10 (versão 1809 ou superior)** ou **Windows 11**.
2.  **Visual Studio 2022** (com a carga de trabalho de *Desenvolvimento para desktop com .NET* e *Desenvolvimento de aplicativos para a Plataforma Universal do Windows* selecionadas).
3.  **.NET 10 SDK** (declarado no `global.json`).

### Método 1: Pelo Visual Studio (Recomendado para desenvolvimento)
1.  Abra o arquivo `SintelAula.sln` no Visual Studio.
2.  Defina o projeto de inicialização como `SintelAula.App` ou `SintelAula.Installer` dependendo de qual parte deseja testar.
3.  Selecione a plataforma de destino como `x64` nas configurações de compilação.
4.  Pressione `F5` para iniciar o build e iniciar a execução com o depurador ativo.

### Método 2: Via Scripts do PowerShell (Automação de Build)
Você pode rodar os scripts utilitários na raiz do projeto para compilar automaticamente e preparar os executáveis otimizados para produção:

*   **Build Geral**:
    ```powershell
    .\build.ps1
    ```
    *Este script valida o ambiente, restaura pacotes NuGet e compila o instalador como um executável auto-contido otimizado.*

*   **Publicação e Remoção de Código Morto (Trimming)**:
    ```powershell
    .\publish_and_update.ps1
    ```
    *Compila o executável com otimização máxima de tamanho (via dotnet publish com PublishTrimmed=true).*

*   **Pacote MSIX para a Microsoft Store**:
    ```powershell
    .\build_msix_store.ps1
    ```
    *Gera o pacote `.msix` pronto para upload na Microsoft Store com os assets de imagem gerados dinamicamente.*

---

## 🎯 Principais Funcionalidades

*   **Inteligência Artificial Local**: Assistente virtual para professores que funciona 100% offline, respeitando a privacidade dos dados escolares.
*   **Gerenciamento Pedagógico**: Criação de planos de aula estruturados e personalizados com base nas diretrizes da escola.
*   **Controle de Turmas e Frequência**: Diário de classe intuitivo para registro rápido de presença e exportação de relatórios.
*   **Lançamento de Notas**: Sistema de avaliações que calcula médias e gera históricos individuais.
*   **Emissão de Relatórios em PDF**: Geração instantânea de boletins, atas de conselho e termos de frequência via biblioteca local.
*   **Tecnologia OCR**: Leitor inteligente de documentos escolares para digitalização rápida de dados.

---

## 💻 Tecnologias Utilizadas

*   **Linguagem**: C# 14 (.NET 10)
*   **Interface Gráfica**: WinUI 3 (Windows App SDK 1.7)
*   **Banco de Dados**: SQLite (via Entity Framework Core 10)
*   **Reconhecimento de Texto (OCR)**: Tesseract OCR (módulo offline)
*   **Processamento e Geração de PDFs**: PdfSharpCore
*   **Empacotamento**: MSIX Packaging

---

## 🛡️ Licença

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para obter mais detalhes.

---
*Desenvolvido com carinho e comprometimento pela equipe **Líbera EdTech**.* 💡🌱
