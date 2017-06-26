# Homework: shell

shell其实在大二上OS的时候有写过，这时候正好重新认识一下shell

shell是一个interface的角色 为用户提供使用操作系统的接口，不属于内核，而是在内核之外以用户态方式进行。基本功能是解释并执行用户打入的命令，实现用户与linux内核的接口。
- input command
- parse the command
- fork a child process
- search the file and load to memory
- finish child process and report to father process
- wait for child process

## 对于可执行命令 使用execv函数

```execv(const char *path, char *const argv[])```
argv是参数列表(指针数组) 第一个参数应当是filename associated with the file being executed. 即argv[0] = path. 还有一点是最后一个参数必须是NULL.

如果正常执行则execv不会返回，如果出错则会返回-1

父子进程拥有不同的内存空间和寄存器，改变一个进程的变量不会影响另一个进程。这里就有一个地方要提到，**cd这种命令是built-in的命令就不能fork一个子进程来执行，改变子进程中的目录是毫无用处的**。

## 对于IO重定向(redirect),这次有机会好好认识一下

file descriptor 每个进程都会维护一张表，文件描述符就是这张表的索引。当程序打开一个现有文件或者创建一个新文件时，内核向进程返回一个文件描述符。内核就通过文件描述符来访问文件。

习惯上 0表示stdin 1表示stdout 2表示stderr shell正是利用这种惯例实现重定向。 系统调用close释放一个文件描述符，未来可以被open重用，因为**一个新分配的文件描述符永远是当前进程的最小的未被使用的文件描述符**。

理解下面这个```cat < input.txt```基本就了解了。

```c
char *argv[2];
argv[0] = "cat";

if(fork() == 0) {
        close(0);
        open("input.txt", O_RDONLY);
        exec("cat", argv);
}
```

关闭文件描述符0后，open的文件input.txt将0作为文件描述符 之后cat就会在标准输入指向input.txt的情况下运行。

文件描述符是一个强大的抽象，因为他们将他们所连接的细节隐藏起来，一个进程向描述符1写出 它有可能是写到一个文件，一个设备，或一个管道。

## 管道(pipe)
"|" 前面指令的输出信息作为后面指令的输入。就是把standard output作为下一个指令的standard input  举个例子 ```ls | grep s```

管道有一个文件描述符对，一个用于写操作，一个用于读操作。这个比较好理解，很直观的管道的既视感。

具体来看作业。

```pipe```函数建立管道，将读写描述符记录在数组p中， p[0]为管道读取端(stdin)，p[1]为管道写入端(stdout)。```dup```复制一个文件描述符，返回一个新的描述符 指向同一个文件。

```c
if(fork1() == 0) 
{
    close(1); //关闭标准输出再dup
    dup(p[1]); //dup将标准输出定向到p[1]指定文件，即管道写入端
    close(p[0]); //关闭端口的引用
    close(p[1]);
    runcmd(pcmd->left);
}
```

在这里 关闭不需要的pipe很重要，避免看不到eof的情况。

最后有一点，**管道命令只会处理标准输出的数据，忽略标准错误输出的数据，管道“|”之后所接的命令必须能够接受标准输入的数据才行，比如ls不能接受标准输入的数据**。

## 文件系统

inode是文件唯一标识符