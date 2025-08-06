import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["errorElement"]

  async create(event) {
    const response = await fetch(this.element.action, {
      method: this.element.method,
      body: new FormData(this.element),
    });

    response.json().then((data) => {
      if (response.ok) {
        navigator.credentials.get({ publicKey: PublicKeyCredential.parseRequestOptionsFromJSON(data) })
          .then((credential) => this.#submitCredential(credential))
          .catch((error) => this.#showError(error));
      } else {
        this.#showError(data.errors?.[0] || "Unknown error");
      }
    });
  }

  #submitCredential(credential) {
    fetch("/webauthn-rails/session/callback", {
      method: "POST",
      body: JSON.stringify(credential),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.getAttribute("content"),
      },
      credentials: "same-origin",
    }).then((response) => {
      if (response.ok) {
        window.location.replace("/");
      } else if (response.status < 500) {
        this.#showError(response.text());
      } else {
        this.#showError("Sorry, something wrong happened.");
      }
    })
  }

  #showError(message) {
    this.errorElementTarget.innerHTML = message;
    this.errorElementTarget.hidden = false;
  }
}
