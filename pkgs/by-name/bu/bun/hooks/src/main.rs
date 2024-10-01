use std::{env, fs, path::Path, process};

#[derive(Debug)]
enum LockContent {
    Text(String),
    Binary(Vec<u8>),
}

#[derive(Debug, serde::Deserialize)]
struct BunLock {
    #[serde(rename = "__version")]
    version: String,
    #[serde(flatten)]
    dependencies: std::collections::HashMap<String, Dependency>,
}

#[derive(Debug, serde::Deserialize)]
struct Dependency {
    version: String,
    #[serde(default)]
    dependencies: std::collections::HashMap<String, String>,
}

fn main() -> anyhow::Result<()>{
    env_logger::init();

    let args = env::args().collect::<Vec<_>>();

    if args.len() < 2 {
        println!("usage: {} <path/to/bun.lock*>", args[0]);
        println!();
        println!("Prefetches bun dependencies for usage by bun.fetchDeps.");

        process::exit(1);
    }

    if let Ok(jobs) = env::var("NIX_BUILD_CORES")
        && !jobs.is_empty()
    {
        rayon::ThreadPoolBuilder::new()
            .num_threads(
                jobs.parse()
                    .expect("NIX_BUILD_CORES must be a whole number"),
            )
            .build_global()
            .unwrap();
    }

    let path = Path::new(&args[1]);
    let is_binary = path
        .extension()
        .map(|ext| ext == "lockb")
        .unwrap_or(false);

    let bytes = fs::read(path)?;
    let lock_content: LockContent = if is_binary {
        LockContent::Binary(bytes)
    } else {
        LockContent::Text(String::from_utf8_lossy(&bytes).into_owned())
    };

    // Parse the lock file content
    match &lock_content {
        LockContent::Text(content) => {
            // Parse bun.lock (JSON format)
            match serde_json::from_str::<BunLock>(content) {
                Ok(lock) => {
                    println!("Parsed bun.lock v{}", lock.version);
                    println!("Dependencies: {}", lock.dependencies.len());
                    for (name, dep) in &lock.dependencies {
                        println!("  {}: {}", name, dep.version);
                    }
                }
                Err(e) => {
                    eprintln!("Failed to parse bun.lock: {}", e);
                }
            }
        }
        LockContent::Binary(bytes) => {
            // Parse bun.lockb (binary format)
            match rmp_serde::decode::from_slice::<BunLock>(bytes) {
                Ok(lock) => {
                    println!("Parsed bun.lockb v{}", lock.version);
                    println!("Dependencies: {}", lock.dependencies.len());
                    for (name, dep) in &lock.dependencies {
                        println!("  {}: {}", name, dep.version);
                    }
                }
                Err(e) => {
                    eprintln!("Failed to parse bun.lockb: {}", e);
                }
            }
        }
    }

    Ok(())
}
