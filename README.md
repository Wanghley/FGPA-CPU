<!-- PROJECT SHIELDS -->
<a name="readme-top"></a>
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/wanghley)

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/wanghley/FPGA-CPU">
    <img src="image.gif" alt="Logo" width="280">
  </a>

  <h3 align="center">FPGA CPU</h3>

  <p align="center">
    Design and simulate a five-stage single-issue 32-bit processor using Verilog.
    <br />
    <a href="#"><strong>Explore the code »</strong></a>
    <br />
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#built-with">Built With</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About The Project

The FPGA CPU project involves designing and simulating a five-stage single-issue 32-bit processor using Verilog. The design integrates a register file, ALU, and multdiv units, and implements pipeline latches, bypassing, and hazard handling to maximize efficiency.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

<img src="https://img.shields.io/badge/Verilog-00599C?style=for-the-badge&logo=verilog&logoColor=white" alt="verilog" style="vertical-align:top; margin:4px"> <img src="https://img.shields.io/badge/Vivado-00599C?style=for-the-badge&logo=vivado&logoColor=white" alt="vivado" style="vertical-align:top; margin:4px">
<img src="https://img.shields.io/badge/GTKWave-00599C?style=for-the-badge&logo=gtkwave&logoColor=white" alt="gtkwave" style="vertical-align:top; margin:4px">

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

To get started with the FPGA CPU project, follow the instructions below:

### Prerequisites

* [Icarus Verilog](https://steveicarus.github.io/iverilog/)
* [GTKWave](http://gtkwave.sourceforge.net/)
* [Vivado](https://www.xilinx.com/products/design-tools/vivado.html)

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/wanghley/FPGA-CPU.git
   ```
2. Open the project in vscode
    ```sh
    code FPGA-CPU
    ```
3. Install the prerequisites
    ```sh
    sudo apt-get install iverilog
    sudo apt-get install gtkwave
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE -->
## Usage

This project involves designing and simulating a five-stage single-issue 32-bit processor using Verilog. The processor integrates a register file, ALU, and multdiv units, and implements pipeline latches, bypassing, and hazard handling to maximize efficiency.

### How to Run

1. Open the project in Vivado.
2. Synthesize and implement the design.
3. Run the simulation to verify the processor's functionality.

### Features

- **Pipeline Stages:**
  - Instruction Fetch (IF)
  - Instruction Decode (ID)
  - Execute (EX)
  - Memory Access (MEM)
  - Write Back (WB)

- **Hazard Handling:**
  - Data hazards
  - Control hazards

- **Bypassing:**
  - Forwarding logic to avoid stalls

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [x] Integrate register file, ALU, and multdiv units
- [ ] Design the processor
- [ ] Implement pipeline stages
- [ ] Optimize hazard handling
- [ ] Improve bypassing logic

See the [open issues](https://github.com/wanghley/FPGA-CPU/issues) for a full list of proposed features and known issues.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

Contributions are welcome! If you have suggestions, improvements, or bug fixes, feel free to open an issue or submit a pull request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

Wanghley Soares Martins - [@wanghley](https://instagram.com/wanghley) - wanghley@wanghley.com

Project Link: [https://github.com/wanghley/FPGA-CPU](https://github.com/wanghley/FPGA-CPU)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Choose an Open Source License](https://choosealicense.com)
* [GitHub Emoji Cheat Sheet](https://www.webpagefx.com/tools/emoji-cheat-sheet)
* [Img Shields](https://shields.io)
* [GitHub Pages](https://pages.github.com)
* [Font Awesome](https://fontawesome.com)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/wanghley/FPGA-CPU?style=for-the-badge
[contributors-url]: https://github.com/wanghley/FPGA-CPU/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/wanghley/FPGA-CPU.svg?style=for-the-badge
[forks-url]: https://github.com/wanghley/FPGA-CPU/network/members
[stars-shield]: https://img.shields.io/github/stars/wanghley/FPGA-CPU.svg?style=for-the-badge
[stars-url]: https://github.com/wanghley/FPGA-CPU/stargazers
[issues-shield]: https://img.shields.io/github/issues/wanghley/FPGA-CPU.svg?style=for-the-badge
[issues-url]: https://github.com/wanghley/FPGA-CPU/issues
[license-shield]: https://img.shields.io/github/license/wanghley/FPGA-CPU.svg?style=for-the-badge
[license-url]: https://github.com/wanghley/FPGA-CPU/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/wanghley
````