#pragma once

//Camera class to handle first - person camera logic
class MazeCamera
{
public:
    // Camera attributes
    glm::vec3 Position;
    glm::vec3 Front;
    glm::vec3 Up;
    glm::vec3 Right;
    // Euler angles
    float Yaw;
    float Pitch;
    // Options
    float MovementSpeed;
    float MouseSensitivity;

    MazeCamera(glm::vec3 startPos, float startYaw, float startPitch)
        : Position(startPos), Yaw(startYaw), Pitch(startPitch), MovementSpeed(3.0f), MouseSensitivity(0.1f)
    {
        // Initialize camera vectors
        Front = glm::vec3(0.0f, 0.0f, -1.0f);
        Up = glm::vec3(0.0f, 1.0f, 0.0f);
        updateCameraVectors();
    }

    // Returns the view matrix using glm::lookAt
    glm::mat4 GetViewMatrix() {
        return glm::lookAt(Position, Position + Front, Up);
    }

    // Process mouse movement (called whenever the mouse moves)
    void ProcessMouseMovement(float xoffset, float yoffset) {
        xoffset *= MouseSensitivity;
        yoffset *= MouseSensitivity;
        Yaw += xoffset;
        Pitch += yoffset;
        // Constrain pitch to avoid flipping over
        if (Pitch > 89.0f)  Pitch = 89.0f;
        if (Pitch < -89.0f) Pitch = -89.0f;
        // Update Front, Right, Up vectors using the updated Euler angles
        updateCameraVectors();
    }

private:
    void updateCameraVectors() {
        // Calculate the new Front vector from the updated Euler angles (Yaw, Pitch)
        glm::vec3 direction;
        direction.x = cos(glm::radians(Yaw)) * cos(glm::radians(Pitch));
        direction.y = sin(glm::radians(Pitch));
        direction.z = sin(glm::radians(Yaw)) * cos(glm::radians(Pitch));
        Front = glm::normalize(direction);
        // Also re-calculate the Right and Up vectors
        Right = glm::normalize(glm::cross(Front, glm::vec3(0.0f, 1.0f, 0.0f)));
        Up = glm::normalize(glm::cross(Right, Front));
    }
};