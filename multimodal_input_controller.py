import cv2
import mediapipe as mp
import numpy as np
import pyautogui
import time
import sounddevice as sd

class HandMouseControl:
    def __init__(self):
        self.mp_hands = mp.solutions.hands
        self.mp_drawing = mp.solutions.drawing_utils
        self.mp_drawing_styles = mp.solutions.drawing_styles
        
        self.cap = cv2.VideoCapture(0)
        self.screen_width, self.screen_height = pyautogui.size()
        self.last_mouse_down_time = 0
        self.last_sound_click_time = 0
        self.hands = self.mp_hands.Hands(
            model_complexity=1,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.7)
        
        # Colors for different hand parts
        self.PALM_COLOR = (255, 0, 0)    # Blue for palm
        self.THUMB_COLOR = (0, 255, 0)   # Green for thumb
        self.INDEX_COLOR = (0, 0, 255)   # Red for index
        self.MIDDLE_COLOR = (255, 255, 0) # Cyan for middle
        self.RING_COLOR = (255, 0, 255)  # Purple for ring
        self.PINKY_COLOR = (0, 255, 255) # Yellow for pinky
        self.CENTER_COLOR = (0, 255, 255) # Yellow for center point

        # Initialize sound detection
        self.sound_threshold = 25
        self.sound_click_delay = 0.2
        self.volume = 0
        self.sound_stream = sd.InputStream(
            callback=self.sound_callback,
            channels=1,
            samplerate=44100
        )
        self.sound_stream.start()

    def sound_callback(self, indata, frames, time, status):
        """Callback function for sound detection"""
        self.volume = np.sqrt(np.mean(indata**2)) * 1000

    def check_sound_click(self):
        """Check for sound click with current volume"""
        if self.volume > self.sound_threshold:
            if time.time() - self.last_sound_click_time > self.sound_click_delay:
                self.last_sound_click_time = time.time()
                return True
        return False

    def run(self):
        while self.cap.isOpened():
            success, image = self.cap.read()
            if not success:
                continue

            image = cv2.cvtColor(cv2.flip(image, 1), cv2.COLOR_BGR2RGB)
            image.flags.writeable = False
            results = self.hands.process(image)

            image.flags.writeable = True
            image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
            
            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    # Draw hand connections
                    self.mp_drawing.draw_landmarks(
                        image,
                        hand_landmarks,
                        self.mp_hands.HAND_CONNECTIONS,
                        self.mp_drawing_styles.get_default_hand_landmarks_style(),
                        self.mp_drawing_styles.get_default_hand_connections_style())
                    
                    # Draw custom landmarks
                    self.draw_custom_landmarks(image, hand_landmarks)
                    
                    # Calculate palm center
                    hand_landmarks_2d = np.array([[landmark.x, landmark.y] for landmark in hand_landmarks.landmark])
                    points = [hand_landmarks_2d[i] for i in [0, 1, 5, 9, 13, 17]]  # Palm points
                    mid_x = int(np.mean([point[0] for point in points]) * image.shape[1])
                    mid_y = int(np.mean([point[1] for point in points]) * image.shape[0])
                    
                    # Draw center point
                    cv2.circle(image, (mid_x, mid_y), 10, self.CENTER_COLOR, -1)
                    cv2.putText(image, "Center", (mid_x + 15, mid_y), 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.7, self.CENTER_COLOR, 2)
                    
                    # Move mouse
                    screen_x = int(mid_x * self.screen_width / image.shape[1])
                    screen_y = int(mid_y * self.screen_height / image.shape[0])
                    pyautogui.moveTo(screen_x, screen_y)
                    
                    # Detect gesture click
                    closest_point_idx = np.argmin([np.linalg.norm(hand_landmarks_2d[i] - [mid_x/image.shape[1], mid_y/image.shape[0]]) 
                                                 for i in range(len(hand_landmarks_2d))])
                    
                    current_time = time.time()
                    if closest_point_idx not in [0, 1, 5, 9, 13, 17] and current_time - self.last_mouse_down_time > 0.2:
                        self.perform_click()
                        self.last_mouse_down_time = current_time

            # Check for sound click
            if self.check_sound_click():
                self.perform_click()

            # Display title and volume level
            cv2.putText(image, "Hand Tracking with Sound Click", (10, 30), 
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.putText(image, f"Sound Level: {int(self.volume)}", (10, 70), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            cv2.imshow('Hand Tracking', image)
            if cv2.waitKey(5) & 0xFF == 27:
                break

        self.cleanup()

    def draw_custom_landmarks(self, image, landmarks):
        image_height, image_width, _ = image.shape
        
        # Palm points (blue)
        palm_indices = [0, 1, 5, 9, 13, 17]
        for idx in palm_indices:
            landmark = landmarks.landmark[idx]
            x = int(landmark.x * image_width)
            y = int(landmark.y * image_height)
            cv2.circle(image, (x, y), 8, self.PALM_COLOR, -1)
            cv2.putText(image, str(idx), (x-10, y-10), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)
        
        # Thumb (green)
        for idx in range(1, 5):
            landmark = landmarks.landmark[idx]
            x = int(landmark.x * image_width)
            y = int(landmark.y * image_height)
            cv2.circle(image, (x, y), 6, self.THUMB_COLOR, -1)
        
        # Index finger (red)
        for idx in range(5, 9):
            landmark = landmarks.landmark[idx]
            x = int(landmark.x * image_width)
            y = int(landmark.y * image_height)
            cv2.circle(image, (x, y), 6, self.INDEX_COLOR, -1)
        
        # Middle finger (cyan)
        for idx in range(9, 13):
            landmark = landmarks.landmark[idx]
            x = int(landmark.x * image_width)
            y = int(landmark.y * image_height)
            cv2.circle(image, (x, y), 6, self.MIDDLE_COLOR, -1)
        
        # Ring finger (purple)
        for idx in range(13, 17):
            landmark = landmarks.landmark[idx]
            x = int(landmark.x * image_width)
            y = int(landmark.y * image_height)
            cv2.circle(image, (x, y), 6, self.RING_COLOR, -1)
        
        # Pinky finger (yellow)
        for idx in range(17, 21):
            landmark = landmarks.landmark[idx]
            x = int(landmark.x * image_width)
            y = int(landmark.y * image_height)
            cv2.circle(image, (x, y), 6, self.PINKY_COLOR, -1)

    def perform_click(self):
        pyautogui.mouseDown()
        pyautogui.mouseUp()

    def cleanup(self):
        self.cap.release()
        self.sound_stream.stop()
        self.sound_stream.close()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    hand_control = HandMouseControl()
    try:
        hand_control.run()
    except KeyboardInterrupt:
        hand_control.cleanup()
        print("Operation terminated")