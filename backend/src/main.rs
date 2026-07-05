#[tokio::main]
async fn main() {
    if let Err(error) = nuara_api::jalankan().await {
        tracing::error!(error = ?error, "Backend Nuara berhenti karena kesalahan");
        std::process::exit(1);
    }
}
