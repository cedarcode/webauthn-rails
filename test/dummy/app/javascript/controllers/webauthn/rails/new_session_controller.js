import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["errorElement"]

  async create() {
    const optionsResponse = await fetch("/webauthn-rails/session/get_options", {
      method: "POST",
      body: new FormData(this.element),
    });

    optionsResponse.json().then((data) => {
      if (optionsResponse.ok) {
        navigator.credentials.get({ publicKey: PublicKeyCredential.parseRequestOptionsFromJSON(data) })
          .then((credential) => this.#submitCredential(credential))
          .catch((error) => this.#showError(error));
      } else {
        this.#showError(data.errors?.[0] || "Unknown error");
      }
    });
  }

  #submitCredential(credential) {
    fetch(this.element.action, {
      method: this.element.method,
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
      } else {
        response.text().then((msg) => {
          const errorMsg = response.status < 500 ? msg : "Sorry, something wrong happened.";
          this.#showError(errorMsg);
        });
      }
    })
  }

  #showError(message) {
    this.errorElementTarget.innerHTML = message;
    this.errorElementTarget.hidden = false;
  }
}
