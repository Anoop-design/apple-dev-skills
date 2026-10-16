---
name: apple-intelligence-ml
description: "Implement or optimize Core ML, Create ML, Vision, Natural Language, and Speech features. Use for model inference, training, image analysis, text analysis, or speech recognition."
license: MIT
---

# Apple ML Frameworks

Choose the framework for the requested inference, training, image analysis, text analysis, or speech task. Preserve the deployment target, model assets, and existing data-flow design.

- [Framework patterns](references/framework-patterns.md): framework-specific examples; read only the relevant section.
- [Core ML optimization](references/coreml-optimization.md): model performance, size, and runtime choices.
- [Vision recipes](references/vision-recipes.md): image analysis workflows.

Verify the relevant API signatures, model inputs/outputs, permissions, and device behavior against the actual project. Test representative inputs and affected failure states; a feature fix does not require retraining a model or changing unrelated framework choices.

Language-model sessions belong to the optional `foundation-models` skill; Image Playground, Writing Tools, and Genmoji belong to `apple-intelligence-ios`. These companions are not required for ML framework work.
