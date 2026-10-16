# Core ML optimization

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Measure the existing model on representative devices before changing its representation or compute-unit configuration. Record accuracy on held-out inputs as well as loading, first prediction, steady-state latency, memory, and energy. Simulator performance isn't a Neural Engine benchmark.

## Compression

Use the installed `coremltools` version's `coremltools.optimize.coreml` APIs. The former `compression_utils` examples are deprecated. For an eligible ML Program model:

```python
import coremltools as ct
import coremltools.optimize.coreml as cto

model = ct.models.MLModel("Model.mlpackage")
config = cto.OptimizationConfig(
    global_config=cto.OpLinearQuantizerConfig(mode="linear_symmetric")
)
compressed = cto.linear_quantize_weights(model, config=config)
compressed.save("ModelCompressed.mlpackage")
```

Linear quantization, palettization (lookup-table indices), and pruning are different operations. “16-bit palettization” is not a recipe for converting float32 to float16. For palettization use `OpPalettizerConfig` with supported bit widths; for pruning use `OpMagnitudePrunerConfig` or `OpThresholdPrunerConfig` and `prune_weights`. Check model type and deployment requirements for each transformation. File-size savings and runtime speedups depend on the graph and hardware; don't promise exact ratios or accuracy preservation.

Pruning arbitrary pretrained weights can damage quality. Use evaluation and calibration/fine-tuning where required. Keep the original model until the compressed candidate meets the feature's acceptance criteria.

## Runtime

- Start with `.all` unless the app has a measured reason to restrict `MLModelConfiguration.computeUnits`. `.cpuAndNeuralEngine` permits those units; it doesn't guarantee every operator runs on the Neural Engine or that it is fastest.
- Distinguish source-model compilation from loading and first-inference specialization. Xcode ordinarily compiles bundled assets during the build. Don't claim every first prediction recompiles the source model.
- Reuse loaded models, but avoid an unsynchronized global mutable cache. Account for the model's concurrency and memory needs.
- Batch predictions only if throughput gains justify batch latency and memory. Preprocess images using the trained orientation, crop, dimensions, color layout, and normalization.
- For delivered model updates, verify file integrity/version compatibility, compile as needed, and replace atomically with a rollback path. Pick the delivery mechanism the app already uses; Background Assets is not required for every model.

Use Xcode's model performance report and appropriate Instruments templates for observed bottlenecks. Set budgets from the product's workload rather than universal “16 ms”, “100 MB”, or “500 ms” thresholds. `.mlmodel`, `.mlpackage`, and `.mlmodelc` describe packaging/compilation; they are not a universal ranking of size or speed.

Official sources: [Core ML model integration](https://developer.apple.com/documentation/coreml/integrating-a-core-ml-model-into-your-app), [Core ML Tools quantization](https://apple.github.io/coremltools/docs-guides/source/opt-quantization-api.html), [Core ML Tools pruning](https://apple.github.io/coremltools/docs-guides/source/opt-pruning-api.html), [Post-training compression](https://apple.github.io/coremltools/docs/source/coremltools.optimize.coreml.post_training_quantization.html).
