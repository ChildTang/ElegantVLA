# ElegantVLA: Learning When to Think for Efficient Vision-Language-Action Models

**NeurIPS 2026**

[Ye Li](https://childtang.github.io/), Huanan Liu, Kangye Ji, Yuan Meng, Jiajun Fan, Yuansong Wang, Shiyu Qin, Chenglei Wu, Shu-Tao Xia, Zhi Wang

[[Project Page]](https://childtang.github.io/ElegantVLA/) [[Paper (arXiv)]](https://arxiv.org/abs/2605.29438) [[Author Homepage]](https://childtang.github.io/)

ElegantVLA is a training-free, plug-in, phase-adaptive inference framework for accelerating
Vision-Language-Action (VLA) models. A lightweight scheduler observes temporal representation
similarity, robot-motion cues, and episode progress to jointly allocate computation across the
vision encoder, LLM, and action head. It achieves up to **2.55×** average speedup on GR00T and
**3.77×** on CogACT, and raises real-world control frequency from **13.8 Hz to 26.3 Hz**.

## Code

Code will be released in this repository. Stay tuned.

## Repository layout

| Branch     | Content                                                        |
|------------|----------------------------------------------------------------|
| `main`     | Source code (coming soon)                                      |
| `gh-pages` | Project page, served at https://childtang.github.io/ElegantVLA/ |

## Citation

```bibtex
@article{li2026elegantvla,
  title={ElegantVLA: Learning When to Think for Efficient Vision-Language-Action Models},
  author={Li, Ye and Liu, Huanan and Ji, Kangye and Meng, Yuan and Fan, Jiajun and Wang, Yuansong and Qin, Shiyu and Wu, Chenglei and Xia, Shu-Tao and Wang, Zhi},
  journal={arXiv preprint arXiv:2605.29438},
  year={2026}
}
```
