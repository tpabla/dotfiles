function comfy --wraps comfy --description 'comfy-cli with a hard MPS memory cap for ComfyUI'
    # Cap PyTorch MPS allocations at ~45 GB (0.58 x 77.8 GB recommended working set).
    # The low watermark defaults to 1.4 and must not exceed the high one.
    PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.58 PYTORCH_MPS_LOW_WATERMARK_RATIO=0.5 command comfy $argv
end
