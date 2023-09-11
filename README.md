# FIFO
三种异步FIFO的实现

分别为普通异步fifo
![image](https://github.com/Howie354/FIFO/assets/105046143/0fdf95fb-db20-4652-a891-2395c83ddbee)

高性能版异步fifo（通过将空将满信号提前产生，cmp模块只需要比较读写的格雷码，不用同步）
![image](https://github.com/Howie354/FIFO/assets/105046143/ba70524c-a079-4684-aab3-8f03b0fe83d0)

深度为1的FIFO
![image](https://github.com/Howie354/FIFO/assets/105046143/fb51aa5e-f949-4de0-b2fc-f6fc5c838236)


