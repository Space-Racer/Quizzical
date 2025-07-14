# 🎡 Spinner Quiz App

A fun and interactive web-based quiz game built with Flutter! Spin the wheel to get a random question, answer it to earn or lose points, and race against the clock.

## ✨ Features

This application is designed to provide a simple yet engaging quiz experience with a vibrant and playful user interface.

* **Interactive Spinner Wheel:**
    * A visually appealing, centrally located spinner.
    * Simply tap the wheel to initiate a spin.
    * Features a smooth, animated spin effect using Flutter's animation controllers, simulating a real-world wheel deceleration.
* **Random Question Delivery:**
    * Upon tapping the spinner, a random question from a pre-defined list of 20 questions is selected and displayed.
    * The questions cover a range of general computing and basic math concepts.
* **Dynamic Scoring System:**
    * "Correct" Button: Awards the player +1 point when clicked, providing positive reinforcement.
    * "Incorrect" Button: Deducts -1 point when clicked, reflecting a missed answer.
    * The current score is prominently displayed at the top of the screen, updating in real-time.
* **Time-Limited Gameplay:**
    * Each game session is timed for 60 seconds (1 minute).
    * A clear countdown timer is visible at the top of the screen, allowing players to monitor their remaining time.
    * The timer visually alerts the player (e.g., flashes red) when the time is running critically low.
* **Game Over & Score Summary:**
    * Once the 60-second timer expires, the game automatically ends.
    * A "Game Over!" dialog pops up, clearly displaying the player's final score for that round.
* **Game Reset Functionality:**
    * After the game ends, the "Game Over" dialog provides an option to "Reset Game".
    * Clicking this button resets the score to zero, clears the current question, and restarts the 60-second timer, allowing for immediate replay.
* **Beautiful & Fun UI/UX:**
    * **Vibrant Color Scheme:** Utilizes a lively palette of deep purples, bright ambers, and blues to create an inviting atmosphere.
    * **Playful Typography:** Custom font (Pacifico example, though any fun font can be used) is applied to enhance the game's lighthearted feel.
    * **Engaging Background:** A custom painter adds subtle, dynamic background elements (like animated circles or shapes) to enhance the visual appeal.
    * **Responsive Layout:** Built with Flutter, ensuring the application adapts seamlessly and looks great on various screen sizes, from mobile browsers to large desktop displays.
    * **Intuitive Buttons:** Clearly labeled "Correct" and "Incorrect" buttons with distinct colors (green for correct, red for incorrect) and icons for easy interaction.

---

## 🎮 Game Mechanics and Rules Tracking Worksheet

### Gameplay Mechanics

Players interact with the game by launching the app and starting from the **Main Menu**. The game supports **two players**, Player 1 and Player 2, who compete by answering questions. The game officially begins when either player presses the "**Start Game**" button.

Once the game starts, a **question appears on the screen**. This game uses **open-ended questions**, meaning each question has only one precise correct answer. Players must **verbally answer the question** before the **10-second timer**, displayed at the top of the screen, runs out.

If a player provides the correct answer within the time limit, they **earn 1 point**. If neither player answers correctly within the 10-second limit, the current question is automatically **skipped**, and no points are awarded or deducted.

The game consists of a total of **25 questions**. After all 25 questions have been presented and answered (or skipped), the game automatically concludes. An "**End of Game**" screen appears, clearly displaying the scores for Player 1 and Player 2, and declares the **winner** (the player with the most points). From this screen, players have the option to "**Restart Game**" to play again or "**Exit App**".

### Rules of the Game

* Answers must **exactly match** the correct stored answer.
* **No external resources** (Google, books, notes, etc.) are allowed during gameplay.
* If no correct answer is provided within **10 seconds**, the question is **skipped**.
* Players **cannot interrupt each other** when answering a question.
* The **score is automatically tracked** by the application.
* The game ends after **all 25 questions** are answered.
* The player with the **highest score wins** the game.

---

## 🚀 Technologies Used

* Flutter
* Dart
