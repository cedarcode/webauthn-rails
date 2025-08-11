import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["errorElement"]

  create(event) {
    event.preventDefault();

    const { fetchResponse } = event.detail;

    fetchResponse.response.json().then((data) => {
      if (fetchResponse.succeeded && data.user) {
        const nickname = event.target.querySelector("input[name='registration[nickname]']")?.value || "";
        const callbackUrl = `/registration/callback?credential_nickname=${encodeURIComponent(nickname)}`;

        navigator.credentials.create({ publicKey: PublicKeyCredential.parseCreationOptionsFromJSON(data) })
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
