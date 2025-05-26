import { Controller } from "@hotwired/stimulus"
import * as WebAuthnJSON from "@github/webauthn-json"

export default class extends Controller {
  static targets = ["errorElement"]

  showError(message) {
    this.errorElementTarget.innerHTML = message;
    this.errorElementTarget.hidden = false;
  }

  postToCallback(callbackUrl, body) {
    fetch(callbackUrl, {
      method: "POST",
      body: JSON.stringify(body),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
      },
      credentials: "same-origin"
    }).then((response) => {
      if (response.ok) {
        window.location.replace("/");
      } else if (response.status < 500) {
        response.text().then((msg) => this.showError(msg));
      } else {
        this.showError("Sorry, something wrong happened.");
      }
    });
  }

  create(event) {
    event.preventDefault();
    const errorElement = this.errorElementTarget;

    event.detail.fetchResponse.response.json().then((response) => {
      if (event.detail.fetchResponse.succeeded) {
        const credentialOptions = response;

        WebAuthnJSON.get({ publicKey: credentialOptions })
          .then((credential) => {
            this.postToCallback("/webauthn-rails/session/callback", credential);
          })
          .catch((error) => {
            this.showError(error);
          });
      } else {
        this.showError(response["errors"][0]);
      }
    });
  }
}
