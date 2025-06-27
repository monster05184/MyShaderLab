using UnityEngine;
using UnityEngine.InputSystem;

public class ModelController : MonoBehaviour
{
    [SerializeField] private Transform cameraTransform;
    [SerializeField] private float rotateSpeed = 100f;
    [SerializeField] private float zoomSpeed = 5f;
    [SerializeField] private float minimumZoom = 2f;
    [SerializeField] private float maximumZoom = 20f;

    private Vector3 modelPosition;
    private float initialCameraDistance;

    private InputAction zoomAction;
    private InputAction rotateAction;
    private InputAction moveAction;

    private void Awake()
    {
        // 初始化输入动作
        zoomAction = new InputAction("Zoom", InputActionType.Value, "<Mouse>/scroll");
        rotateAction = new InputAction("Rotate", InputActionType.Value, "<Mouse>/delta");
        moveAction = new InputAction("Move", InputActionType.Value, "<Keyboard>/w,<Keyboard>/a,<Keyboard>/s,<Keyboard>/d,<Keyboard>/upArrow,<Keyboard>/downArrow,<Keyboard>/leftArrow,<Keyboard>/rightArrow");

        zoomAction.Enable();
        rotateAction.Enable();
        moveAction.Enable();
    }

    private void Start()
    {
        // 初始化相机位置
        initialCameraDistance = Vector3.Distance(cameraTransform.position, transform.position);
    }

    private void Update()
    {
        // 缩放模型
        //HandleZoom();

        // 旋转模型
        HandleRotation();

        // 移动相机视角
        //HandleCameraMovement();
    }

    private void HandleZoom()
    {
        // 使用鼠标滚轮进行缩放
        float zoom = zoomAction.ReadValue<Vector2>().y;
        if (zoom != 0)
        {
            float newDistance = Vector3.Distance(cameraTransform.position, transform.position) - (zoom * zoomSpeed * Time.deltaTime);
            newDistance = Mathf.Clamp(newDistance, minimumZoom, maximumZoom);

            // 计算新的相机位置
            Vector3 direction = (cameraTransform.position - transform.position).normalized;
            cameraTransform.position = transform.position + direction * newDistance;
        }
    }

    private void HandleRotation()
    {
        // 使用鼠标左键拖动进行绕y轴旋转
        if (Mouse.current.leftButton.isPressed)
        {
            Vector2 mouseDelta = rotateAction.ReadValue<Vector2>();
            float mouseX = mouseDelta.x * rotateSpeed * Time.deltaTime;

            // 绕模型中心点的y轴旋转
            transform.RotateAround(transform.position, Vector3.up, mouseX);
        }
    }
    
    private void HandleCameraMovement()
    {
        
        // 如果相机没有设置，则返回
        if (cameraTransform == null)
        {
            Debug.LogWarning("Camera Transform is not set.");
            return;
        }
        // 使用WASD或箭头键移动相机
        Vector2 moveInput = moveAction.ReadValue<Vector2>();
        float moveSpeed = 5f * Time.deltaTime;
        
        Vector3 cameraPosition = cameraTransform.position;
        // 移动相机位置
        cameraPosition += cameraTransform.forward * moveInput.y * moveSpeed;
        cameraPosition += cameraTransform.right * moveInput.x * moveSpeed;

        cameraTransform.position += cameraPosition;
        cameraTransform.position += cameraPosition;
    }

    private void OnDestroy()
    {
        // 禁用输入动作
        zoomAction.Disable();
        rotateAction.Disable();
        moveAction.Disable();
    }
}