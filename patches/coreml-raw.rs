/*
Parakeet TDT transcription with CoreML (Apple Metal GPU) support.

This is a patched version of the raw example that uses CoreML execution provider
for GPU acceleration on Apple Silicon Macs.

Usage:
cargo run --example raw --features coreml -- audio.wav tdt

Note: CoreML compilation happens on first run and may take a few seconds.
Subsequent runs use cached compiled models for faster startup.

Important: CoreML requires int8 quantized models without external data files.
Use `make download-models-coreml` to download compatible models.
*/

use parakeet_rs::{ExecutionConfig, ExecutionProvider, ParakeetTDT, TimestampMode, Transcriber};
use std::env;
use std::time::Instant;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let start_time = Instant::now();
    let args: Vec<String> = env::args().collect();
    let audio_path = if args.len() > 1 {
        &args[1]
    } else {
        "test.wav"
    };

    let use_tdt = args.len() < 3 || args[2] == "tdt";

    if !use_tdt {
        eprintln!("Error: CoreML build only supports TDT model");
        std::process::exit(1);
    }

    let mut reader = hound::WavReader::open(audio_path)?;
    let spec = reader.spec();

    println!(
        "Audio info: {}Hz, {} channel(s)",
        spec.sample_rate, spec.channels
    );

    let audio: Vec<f32> = match spec.sample_format {
        hound::SampleFormat::Float => reader.samples::<f32>().collect::<Result<Vec<_>, _>>()?,
        hound::SampleFormat::Int => reader
            .samples::<i16>()
            .map(|s| s.map(|s| s as f32 / 32768.0))
            .collect::<Result<Vec<_>, _>>()?,
    };

    // Use CoreML execution provider for Apple Metal GPU acceleration
    let config = ExecutionConfig::new().with_execution_provider(ExecutionProvider::CoreML);

    println!("Loading TDT model with CoreML (Metal GPU)...");
    // Load from current directory (parakeet-cli runs from $MODELS_DIR)
    // CoreML requires int8 models: encoder-model.int8.onnx, decoder_joint-model.int8.onnx
    let mut parakeet = ParakeetTDT::from_pretrained("./tdt", Some(config))?;

    let result = parakeet.transcribe_samples(
        audio,
        spec.sample_rate,
        spec.channels,
        Some(TimestampMode::Sentences),
    )?;

    println!("{}", result.text);
    println!("\nSentencess:");
    for segment in result.tokens.iter() {
        println!(
            "[{:.2}s - {:.2}s]: {}",
            segment.start, segment.end, segment.text
        );
    }

    let elapsed = start_time.elapsed();
    println!(
        "\n✓ Transcription completed in {:.2}s",
        elapsed.as_secs_f32()
    );

    Ok(())
}
