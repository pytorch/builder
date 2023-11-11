import torch


def foo(x: torch.Tensor) -> torch.Tensor:
    return torch.sin(x) + torch.cos(x)


if __name__ == "__main__":
    x = torch.rand(3, 3, device="cuda")
    x_eager = foo(x)
    x_pt2 = torch.compile(foo)(x)
    print(torch.allclose(x_eager, x_pt2))
