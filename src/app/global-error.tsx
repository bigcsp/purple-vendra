"use client";

/** Last-resort screen if the whole site layout fails. Uses plain styles on purpose. */
export default function GlobalError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: "system-ui, sans-serif", background: "#fbf8ff", color: "#1a1024" }}>
        <main style={{ maxWidth: 440, margin: "15vh auto", padding: 20, textAlign: "center" }}>
          <p style={{ fontSize: 22, fontWeight: 800, color: "#6d28d9" }}>Purple Shop</p>
          <h1 style={{ fontSize: 22 }}>Purple Shop is having trouble right now</h1>
          <p style={{ color: "#6b6478" }}>Please try again in a minute.</p>
          <button
            onClick={reset}
            style={{ marginTop: 12, background: "#6d28d9", color: "#fff", border: 0, borderRadius: 999, padding: "10px 20px", fontSize: 15 }}
          >
            Try again
          </button>
        </main>
      </body>
    </html>
  );
}
