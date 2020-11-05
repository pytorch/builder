import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim

class test(nn.Module):
    def __init__(self):
        super(test, self).__init__()
        self.conv1 = nn.Conv2d(1,1,3)
        self.pool = nn.MaxPool2d(2, 2)
        
    def forward(self, input):
        x = self.pool(F.relu(self.conv1(input)))
        x = x.view(1)
        return x

device = torch.device("cuda:0")
net = test().to(device)
inputs = torch.rand((1, 1, 5, 5), device=device)
# check cudnn_ops_infer64_8.dll and cudnn_cnn_infer64_8.dll
outputs = net(inputs)
print(outputs)

# Mock one step training, check cudnn_ops_train64_8.dll and cudnn_cnn_train64_8.dll
criterion = nn.MSELoss()
optimizer = optim.SGD(net.parameters(), lr=0.001, momentum=0.1)
label = torch.full((1,), 1.0, dtype=torch.float, device=device)

loss = criterion(outputs, label)
loss.backward()
optimizer.step()



