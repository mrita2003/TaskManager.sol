// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract TaskManager {

    // Struct to represent a task
    struct Task {
        string description;
        uint256 deadline;
        address assignedTo;
        bool completed;
        uint8 category; // 1: personal, 2: work, 3: study, etc;
        uint256 reward; // Amount to be paid for completing the task
        bool rewardPaid; // Indicates whether the reward has been paid
    }

    // Mapping to store tasks assigned to each user
    mapping(address => Task[]) public userTask;

    // Mapping to hold funds in escrow for each task
    mapping(address => mapping(uint256 => uint256)) public taskEscrow;

    // Event to emit upon task creation, completion, and payment
    event TaskCreated(address indexed assignedTo, string description, uint256 deadline, uint8 category, uint256 reward);
    event TaskCompleted(address indexed assignedTo, string description);
    event PaymentReleased(address indexed recipient, uint256 amount);

    // Function to create a new task
    function createTask(
        string memory _description,
        uint256 _deadline,
        address _assignedTo,
        uint8 _category,
        uint256 _reward
    ) external payable {
        require(_assignedTo != address(0), "Invalid address");
        require(_deadline > block.timestamp, "Invalid deadline");
        require(_reward > 0, "Reward must be greater than zero");

        Task memory newTask = Task({
            description: _description,
            deadline: _deadline,
            assignedTo: _assignedTo,
            completed: false,
            category: _category,
            reward: _reward,
            rewardPaid: false
        });

        userTask[_assignedTo].push(newTask);
        taskEscrow[_assignedTo][userTask[_assignedTo].length - 1] = msg.value;

        emit TaskCreated(_assignedTo, _description, _deadline, _category, _reward);
    }

    // Function to mark a task as completed and release payment
    function completeTask(address _user, uint256 _taskIndex) external {
        require(_taskIndex < userTask[_user].length, "Invalid task index");
        require(!userTask[_user][_taskIndex].completed, "Task already completed");

        userTask[_user][_taskIndex].completed = true;

        // Release payment
        require(!userTask[_user][_taskIndex].rewardPaid, "Reward already paid");
        userTask[_user][_taskIndex].rewardPaid = true;
        uint256 amount = taskEscrow[_user][_taskIndex];
        taskEscrow[_user][_taskIndex] = 0;
        payable(_user).transfer(amount);

        emit TaskCompleted(_user, userTask[_user][_taskIndex].description);
        emit PaymentReleased(_user, amount);
    }

    // Function to get the total number of tasks assigned to a user
    function getTotalTask(address _user) external view returns (uint256) {
        return userTask[_user].length;
    }

    // Function to get details of a specific task assigned to a user
    function getTaskDetails(address _user, uint256 _taskIndex) external view returns (
        string memory description,
        uint256 deadline,
        address assignedTo,
        bool completed,
        uint8 category,
        uint256 reward,
        bool rewardPaid
    ) {
        require(_taskIndex < userTask[_user].length, "Invalid task index");

        Task memory task = userTask[_user][_taskIndex];

        return (
            task.description,
            task.deadline,
            task.assignedTo,
            task.completed,
            task.category,
            task.reward,
            task.rewardPaid
        );
    }
}
