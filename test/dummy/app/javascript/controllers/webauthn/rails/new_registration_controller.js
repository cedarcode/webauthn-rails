import { Controller } from "@hotwired/stimulus";
import * as WebAuthnJSON from "@github/webauthn-json";

export default class extends Controller {
  static targets = ["errorElement"]

  create(event) {
    event.preventDefault();

    const { fetchResponse } = event.detail;

    fetchResponse.response.json().then((data) => {
      if (fetchResponse.succeeded && data.user) {
        const nickname = event.target.querySelector("input[name='registration[nickname]']")?.value || "";
        const callbackUrl = `/webauthn-rails/registration/callback?credential_nickname=${encodeURIComponent(nickname)}`;

        WebAuthnJSON.create({ publicKey: data })
          .then((credential) => this.#submitRegistration(callbackUrl, credential))
          .catch((error) => this.#showError(error));
      } else {
        this.#showError(data.errors?.[0] || "Unknown error");
      }
    });
  }

  #submitRegistration(url, credential) {
    fetch(url, {
      method: "POST",
      body: JSON.stringify(credential),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
      },
      credentials: "same-origin"
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
