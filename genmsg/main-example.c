/* LICENSE=GPL */

/* caliper uinput driver
** written by vordah@gmail.com
*/

/* compile with libusb, use gcc -lusb -lpthread */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h> /* isalpha */
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <errno.h>
#include <pthread.h>
#include <signal.h>
#include <asm/types.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <malloc.h>
// #include <hid.h>
#include <termios.h> /* POSIX terminal control definitions */
#include <lockdev.h> /* serial line locking */
#include <bluetooth/bluetooth.h>
#include <bluetooth/rfcomm.h>

#include "cmdline.h"
// #include "input_keynames.h"
#include "caliper.h"
#include "keypress.h"
#include "beep.h"
#include "threads.h"


pthread_mutex_t conn_mutex = PTHREAD_MUTEX_INITIALIZER;

#define TIMEOUT 3000
#define WAITINBETWEEN 500000

/* udp server */
#define BUFLEN 512
#define PORT 32001

/* From HID specification */
#define SET_REQUEST 0x21
#define SET_REPORT 0x09 
#define OUTPUT_REPORT_TYPE 0x02

/* Global list of FDs each object is interested in,
** and FDs that there have been activity on. Each object
** adds itself to the fd_request_* lists on creation and removes
** itself on deletion, and checks the fd_* lists on poll.
*/
#ifdef USE_DSELECT
static fd_set fd_request_read, fd_request_write, fd_request_except;
static fd_set fd_read, fd_write, fd_except;

int fd_count = 0;
#endif

struct gengetopt_args_info args_info;
struct gengetopt_args_info *args = &args_info;

int verbose = 0;

struct caliper caliper;

struct timeval tv;
int sec,msec,oldsec,dif,sec0;
int count = 0;

void *(*input_handler)(void *data) = NULL;

/* source input device register */
int input_register_serial(struct caliper *device)
{
  int fd;
  struct termios options;

  device->connected = 0;

  /* open source device file */
  if(device->name == NULL)
  {
    perror("no source input device specified");
    return -1;
  }

  /* lock the originating serial line */
  if(dev_lock(device->name))
  {
    perror("cannot get hold of the device lock");
    return -1;
  }

  /* device->hwfd = open(device->name, O_RDONLY | O_NOCTTY | O_SYNC); */
  device->hwfd = open(device->name, O_RDWR | O_NOCTTY | O_SYNC);
  if(device->hwfd < 0)
  {
    perror("open source input device");
    return -1;
  }

  fd = device->hwfd;

  /* set serial parameters (9600,N,1) */
  fcntl(fd, F_SETFL, 0);
  
  /* Get the current options for the port */
  tcgetattr(fd, &options);

  /* Set the baud rates to 9600 */
  cfsetispeed(&options, device->bps);
  cfsetospeed(&options, device->bps);

  /* Enable the receiver and set local mode */
  options.c_cflag |= (CLOCAL | CREAD);

  switch(device->parity)
  {
    case(PARITY_NONE):
      options.c_cflag &= ~PARENB;
      options.c_cflag &= ~CSTOPB;
      options.c_cflag &= ~CSIZE;
      options.c_cflag |= CS8;
      break;
    case(PARITY_ODD):
      options.c_cflag |= PARENB;
      options.c_cflag |= PARODD;
      options.c_cflag &= ~CSTOPB;
      options.c_cflag &= ~CSIZE;
      options.c_cflag |= CS7;
      break;
    case(PARITY_EVEN):
      options.c_cflag |= PARENB;
      options.c_cflag &= ~PARODD;
      options.c_cflag &= ~CSTOPB;
      options.c_cflag &= ~CSIZE;
      options.c_cflag |= CS7;
      break;  
  }

  options.c_iflag |= IGNBRK;
  options.c_iflag &= ~IGNBRK;
  options.c_iflag &= ~ICRNL;
  options.c_iflag &= ~INLCR;
  options.c_iflag &= ~IMAXBEL;
  options.c_iflag &= ~IXON;
  options.c_iflag &= ~IXOFF;

  options.c_oflag &= ~OPOST;
  options.c_oflag &= ~ONLCR;

  options.c_lflag &= ~ISIG;
  options.c_lflag &= ~ICANON;
  options.c_lflag &= ~IEXTEN;
  options.c_lflag &= ~ECHO;
  options.c_lflag &= ~ECHOE;
  options.c_lflag &= ~ECHOK;
  options.c_lflag |= NOFLSH;
  options.c_lflag &= ~ECHOCTL;
  options.c_lflag &= ~ECHOKE;

  options.c_cc[VTIME] = 0;
  options.c_cc[VMIN] = 1;
  /* Set the new options for the port */
  tcsetattr(fd, TCSANOW, &options);

  input_handler = input_handler_serial;

  usleep(100000); /* port open grace time */
  device->connected = 1;

  return 0;
}

/* source input device register */
int input_register_bluetooth(struct caliper *device)
{
  struct sockaddr_rc addr = { 0 };
  int status;

  device->connected = 0;
  /* allocate a socket */
  device->hwfd = socket(AF_BLUETOOTH, SOCK_STREAM, BTPROTO_RFCOMM);

  /* set the connection parameters (who to connect to) */
  addr.rc_family = AF_BLUETOOTH;
  addr.rc_channel = (uint8_t) 1;
  str2ba( device->name, &addr.rc_bdaddr );

  /* connect to server (bluetooth slave) */
  status = connect(device->hwfd, (struct sockaddr *)&addr, sizeof(addr));

  if(status < 0)
  {
    perror("bluetooth");
    return -1;
  }

  input_handler = input_handler_serial;

  device->connected = 1;
  return 0;
}

int input_register_udp(struct caliper *device)
{
    struct sockaddr_in my_addr;
    // struct sockaddr_rc addr = { 0 };
    // int i;
    // struct sockaddr_in cli_addr;
    // socklen_t slen=sizeof(cli_addr);
    // char buf[BUFLEN];

    if ((device->hwfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1)
    {
      perror("socket");
      return -1;
    }
    else
      printf("Server : Socket() successful\n");
 
    bzero(&my_addr, sizeof(my_addr));
    my_addr.sin_family = AF_INET;
    my_addr.sin_port = htons(PORT);
    my_addr.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(device->hwfd, (struct sockaddr* ) &my_addr, sizeof(my_addr))==-1)
    {
      perror("bind");
      return -1;
    }
    else
      printf("Server : bind() successful\n");

#if 0
    if (connect(device->hwfd, (struct sockaddr *)&addr, sizeof(addr) )==-1)
    {
      perror("connect");
      return -1;
    }
    else
      printf("Server : connect() successful\n");
#endif

  input_handler = input_handler_udp;

  device->connected = 1;
  return 0;
}

int input_register(struct caliper *device)
{
  /* open source device file */
  if(device->name == NULL)
  {
    perror("no source input device specified");
    return -1;
  }

  if(device->name[0] == '/')
    return input_register_serial(device);
    
  if(strncmp(device->name, "udp", 3) == 0)
    return input_register_udp(device);

  return input_register_bluetooth(device);
}


/* register the caliper in uinput system as
** keyboard device with keys for nimbers,
** decimal point and next field key (usually down arrow)
*/
int uinput_register(struct caliper *device)
{
  int fd;
  struct keysequence *ptr, *sequence;
  int i;

  /* uinput initialization */
#ifdef USE_DSELECT
  FD_ZERO(&fd_request_read);
  FD_ZERO(&fd_request_write);
  FD_ZERO(&fd_request_except);
#endif
  
  /* open uinput device file */
  fd = open("/dev/uinput", O_RDWR);
  if (fd < 0) {
    perror("open uinput device");
    return -1;
  }

  device->uifd = fd;

  /* sets the name of our device */
  strcpy(device->device.name, "Autoinput");

  /* sets maximum number of simultaneous force feedback effects */
  device->device.ff_effects_max = 0;
  
  /* its bus */
  device->device.id.bustype = BUS_RS232; /* or BUS_BLUETOOTH */
  
  /* and id/vendor id/product id/version
  ** we will create with uinput
  ** (not need to be the same as the hardware device)
  */
  device->device.id.vendor = 0x1547; /* This is Mitutoyo PCI ID */
  device->device.id.product = 0x232;
  device->device.id.version = 1;
  
  /* inform that we'll generate key events */
  ioctl(fd, UI_SET_EVBIT, EV_KEY);

  /* inform that we'll generate miscellaneous events */
  ioctl(fd, UI_SET_EVBIT, EV_MSC);

#if 0
  /* inform that we'll generate relative device pointer events */
  if(device->noclicks == 0)
    ioctl(fd, UI_SET_EVBIT, EV_REL);
#endif

#if 0
  /* inform that we have force feedback */
  ioctl(fd, UI_SET_EVBIT, EV_FF);
#endif

#if 0
  /* inform that we have LED */
  ioctl(fd, UI_SET_EVBIT, EV_LED);
#endif

#if 0
  /* set keyboard events we can generate (in this case, all) */
  for (aux = 1; aux < 207; aux++)
    ioctl(fd, UI_SET_KEYBIT, aux);
#endif

  /* scancodes */
  ioctl(fd, UI_SET_MSCBIT, MSC_SCAN);

  for(i = 0; i < 256; i++)
  {
    sequence = device->ascii2key[i];
    
    for(ptr = sequence; ptr != NULL; ptr = ptr->next)
    {
      ioctl(fd, UI_SET_KEYBIT, ptr->key);
    }
  }

#if 0
  /* keypad */
  ioctl(fd, UI_SET_KEYBIT, KEY_KP0);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP1);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP2);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP3);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP4);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP5);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP6);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP7);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP8);
  ioctl(fd, UI_SET_KEYBIT, KEY_KP9);
  ioctl(fd, UI_SET_KEYBIT, KEY_KPDOT);
  ioctl(fd, UI_SET_KEYBIT, KEY_KPMINUS);
  ioctl(fd, UI_SET_KEYBIT, KEY_KPPLUS);
  ioctl(fd, UI_SET_KEYBIT, KEY_ENTER);

  /* keyboard backspace */
  ioctl(fd, UI_SET_KEYBIT, KEY_BACKSPACE);
  
  /* arrow keys */
  ioctl(fd, UI_SET_KEYBIT, KEY_LEFT);
  ioctl(fd, UI_SET_KEYBIT, KEY_RIGHT);
  ioctl(fd, UI_SET_KEYBIT, KEY_UP);
  ioctl(fd, UI_SET_KEYBIT, KEY_DOWN);
#endif

#if 0
  /* set LED we can display */
  ioctl(fd, UI_SET_LEDBIT, LED_MISC);
  /* ioctl(fd, UI_SET_LEDBIT, LED_SLEEP); */
#endif
  
  /* write down information for creating a new device */
  if (write(fd, &(device->device), sizeof(struct uinput_user_dev)) < 0) {
    perror("write");
    close(fd);
    return 1;
  }

  /* actually creates the device */
  ioctl(fd, UI_DEV_CREATE);

#ifdef USE_DSELECT
  /* now we can register our uinput device for select() */
  FD_SET(fd, &fd_request_read);
  if(fd >= fd_count)
    fd_count = fd + 1;
#endif

  return 0;
}


/* unregister the source device
*/
int input_unregister(struct caliper *device)
{
  device->connected = 0;

  /* source de-initialization */
  close(device->hwfd);

  /* release our device lock */
  dev_unlock(device->name, getpid());

  return 0;
}

/* serial port and bluetooth input handler */
void *input_handler_serial(void *data)
{
  fd_set rfds;
  struct timeval tv;
  struct caliper *device = (struct caliper *) data;
  struct input_event event;
  int fd, retval, status;
  int unknown_data = 0;
  char input[BUFLEN];
  struct timeval time_now[1], time_prev[1];
  int dsec, dusec;
  int dt;
  
  memset(time_now,  0, sizeof(time_now));
  memset(time_prev, 0, sizeof(time_prev));

 persist:;
  if(device->connected == 0)
  {
    status = input_register(device);
    if(status != 0 && device->persist > 0)
    {
      input_unregister(device);
      sleep(1);
      goto persist;
    }
  }
  if(verbose)
    printf("connected\n");
  fd = device->hwfd;
  // input[0] = '\n';
  input[0] = '\0';
  for(retval = 0; retval >= 0 && unknown_data < 1000;)
  {
    // printf("state %d\n", device->state);
    switch(device->state)
    {
      case STATE_IDLE:
        retval = read(fd, input, 1); /* read char-by-char serial, infinite idle time */
        break;
      case STATE_IDLE60S:
        FD_ZERO(&rfds);
        FD_SET(fd, &rfds);
        tv.tv_sec = 60; /* tv.tv_sec = 60 timeout of 60 seconds for 1-minute idle states */
        tv.tv_usec = 0;
        if(select(fd + 1, &rfds, NULL, NULL, &tv) > 0)
        {
          retval = read(fd, input, 1);
        }
#if 1
        else
        {
          /* fake receiving NULL-char to keep states refresing balance
          ** command to send data on keypress */
          input[0] = '\0';
          retval = 1;
        }
#endif
        break;
      default:
        FD_ZERO(&rfds);
        FD_SET(fd, &rfds);
        tv.tv_sec = 0; /* timeout of 0.7 second for non-idle states */
        tv.tv_usec = 700000;
        if(select(fd + 1, &rfds, NULL, NULL, &tv) > 0)
          retval = read(fd, input, 1);
        else
        {
          input[0] = '\0';
          retval = 1;
        }
        break;
    }

    if(verbose)
    {
      if(isascii(input[0]) && isprint(input[0]) && !iscntrl(input[0]))
        printf("input activity '%c'\n", input[0]);
      else
        printf("input activity 0x%02x\n", input[0]);
    }

    /* debounce: minimum delay between data */
    if(key_convert(device, input[0], &event) > 0)
    {
      unknown_data = 0;

      gettimeofday(time_now, NULL); /* timestamp of data from idle state */
      /* calculate time difference between incoming data during idle state */
      dsec  = time_now->tv_sec  - time_prev->tv_sec;
      dusec = time_now->tv_usec - time_prev->tv_usec;      
      dt = 1000000 * dsec + dusec; /* time difference in useconds */
      if(dt < 0)
        dt = -dt; /* abs value */
      if(dt < device->debounce)
      {
        if(verbose)
          printf("debounce time not reached %d < %d\n", dt, device->debounce);
      }
      else
      {
        /* make audible beep when keypresses are generated */
        beep(device, 1);
        memcpy(time_prev, time_now, sizeof(time_prev));
        if(rc[THREAD_KEYPRESS] == 0)
          pthread_join( thread[THREAD_KEYPRESS], NULL);

        strcpy(device->sendvalue, device->value);
        if(verbose)
          printf("got: %s (%ld bytes)\n", device->sendvalue, strlen(device->sendvalue));

        if(device->sendvalue[0] != '\0')
          rc[THREAD_KEYPRESS] = pthread_create( &thread[THREAD_KEYPRESS], NULL, &keypress_handler, (void *) (device) );
      }
    }
    else
      unknown_data++;
  }
  if(device->persist > 0)
  {
    input_unregister(device);
    goto persist;
  }
//  pthread_exit(0);
  return NULL;
}

/* udp handler, UDP recvfrom */
void *input_handler_udp(void *data)
{
  struct sockaddr_in cli_addr;
  socklen_t slen=sizeof(cli_addr);
  struct caliper *device = (struct caliper *) data;
  struct input_event event;
  int fd, status;
  int unknown_data = 0;
  char input[BUFLEN];
  int i, n;
  ssize_t len;

 persist:;
  if(device->connected == 0)
  {
    status = input_register(device);
    if(status != 0 && device->persist > 0)
    {
      input_unregister(device);
      sleep(1);
      goto persist;
    }
  }
  if(verbose)
    printf("connected\n");
  
  fd = device->hwfd;
  for(;;)
  {
    len = recvfrom(fd, input, BUFLEN-1, 0, (struct sockaddr*)&cli_addr, &slen);
    if(len > 0)
    {
    n = len;
    if(n > BUFLEN-1)
     n = BUFLEN-1;
    if(n < 0)
     n = 0;
    
    /* force 0-termination if input string isn't 0-terminated */
    if(input[n] != '\0')
    {
      input[n] = '\0';
      n++;
    }

    if(verbose)
      printf("udp input activity '%s' (len=%d)\n", input, n);
        
    for(i = 0; i < n; i++)
      if(key_convert(device, input[i], &event))
      {
        unknown_data = 0;
        if(rc[THREAD_KEYPRESS] == 0)
          pthread_join( thread[THREAD_KEYPRESS], NULL);

        strcpy(device->sendvalue, device->value);
        if(verbose)
          printf("got: %s\n", device->sendvalue);

        rc[THREAD_KEYPRESS] = pthread_create( &thread[THREAD_KEYPRESS], NULL, &keypress_handler, (void *) (device) );
      }
      else
        unknown_data++;
    }
  }
  if(unknown_data)
    printf("unknown data: %d\n", unknown_data);
  if(device->persist > 0)
  {
    input_unregister(device);
    goto persist;
  }
//  pthread_exit(0);
  return NULL;
}



/* unregister the device from uinput system
*/
int uinput_unregister(struct caliper *device)
{
  /* uinput de-initialization */
  close(device->uifd);

  return 0;
}

void timer_handler(int signum)
{
  struct caliper *device = &caliper;
  struct input_event syn, event;

  pthread_mutex_lock(&mutex1);
  
  gettimeofday(&tv,NULL);
  sec = (tv.tv_sec-sec0)*1000 + (tv.tv_usec/1000);
  dif = sec-oldsec;
  oldsec = sec;
#if 0
  printf("count %d delay %d  \n", ++count,dif);
#endif
  syn.type = EV_SYN;
  syn.code = SYN_REPORT;
  syn.value = 0;

//  event = device->last_cursor;
  event.value = 0;

  write(device->uifd, &event, sizeof(struct input_event));
  write(device->uifd, &syn, sizeof(struct input_event));

  pthread_mutex_unlock(&mutex1);
}


int main(int argc, char *argv[])
{
  int i, n = THREAD_MAX;
  struct caliper *device = &caliper;
  struct sigaction sa;

  for(i = 0; i < n; i++)
    rc[i] = -1;

  memset(device, 0, sizeof(*device));
  device->state = STATE_IDLE60S;

  cmdline_parser(argc, argv, args);
  device->name = args->device_arg;
  device->protocol = PROTOCOL_SIMPLE;
  if(args->protocol_given)
  {
    if(strcasecmp("denver", args->protocol_arg) == 0)
      device->protocol = PROTOCOL_DENVER;
    if(strcasecmp("bosch", args->protocol_arg) == 0)
      device->protocol = PROTOCOL_DENVER;
    if(strcasecmp("kern", args->protocol_arg) == 0)
      device->protocol = PROTOCOL_DENVER;
    if(strcasecmp("sartorious", args->protocol_arg) == 0)
      device->protocol = PROTOCOL_DENVER;
    if(strcasecmp("mettlertoledo", args->protocol_arg) == 0)
      device->protocol = PROTOCOL_METTLERTOLEDO;
    if(strcasecmp("mettler-toledo", args->protocol_arg) == 0)
      device->protocol = PROTOCOL_METTLERTOLEDO;
    if(strcasecmp("simple", args->protocol_arg) == 0)
      device->protocol = PROTOCOL_SIMPLE;
  }
  device->bps = B9600;
  if(args->bps_given)
  {
    switch(args->bps_arg)
    {
      case 1200:
        device->bps = B1200;
        break;
      case 2400:
        device->bps = B2400;
        break;
      case 4800:
        device->bps = B4800;
        break;
      case 9600:
        device->bps = B9600;
        break;
      case 19200:
        device->bps = B19200;
        break;
      case 38400:
        device->bps = B38400;
        break;
      case 57600:
        device->bps = B57600;
        break;
      case 115200:
        device->bps = B115200;
        break;
      default:
        printf("Unsupported baud rate: %d\n", args->bps_arg);
        break;
    }
  }
  device->parity = PARITY_NONE;
  if(args->parity_given)
  {
    device->parity = -1;
    if(strcasecmp("none", args->parity_arg) == 0)
      device->parity = PARITY_NONE;
    if(strcasecmp("odd", args->parity_arg) == 0)
      device->parity = PARITY_ODD;
    if(strcasecmp("even", args->parity_arg) == 0)
      device->parity = PARITY_EVEN;
    if(device->parity == -1)
      printf("Unsupported parity: %s\n", args->parity_arg);
  }
  device->suppress_plus = args->plus_given ? 0 : 1;
  device->suppress_zero = args->zero_given ? 0 : 1;
  device->speakername = args->pcspeaker_arg;
  device->output_delay = args->key_delay_arg;
  device->persist = args->persist_given ? 1 : 0;
  device->connected = 0;
  
  device->debounce = 2000000;
  if(args->debounce_given)
    device->debounce = args->debounce_arg;

  verbose = args->verbose_given ? 1 : 0;

  if(strcasecmp("num", args->key_layout_arg) == 0)
  {
    pressrelease(device, '0', KEY_KP0);
    pressrelease(device, '1', KEY_KP1);
    pressrelease(device, '2', KEY_KP2);
    pressrelease(device, '3', KEY_KP3);
    pressrelease(device, '4', KEY_KP4);
    pressrelease(device, '5', KEY_KP5);
    pressrelease(device, '6', KEY_KP6);
    pressrelease(device, '7', KEY_KP7);
    pressrelease(device, '8', KEY_KP8);
    pressrelease(device, '9', KEY_KP9);

    pressrelease(device, '.', KEY_KPDOT);
    pressrelease(device, '+', KEY_KPPLUS);
    pressrelease(device, '-', KEY_KPMINUS);
    pressrelease(device, ')', KEY_DOWN);
    pressrelease(device, '?', KEY_KPENTER);
  }

  if(strcasecmp("key", args->key_layout_arg) == 0)
  {
    pressrelease(device, '0', KEY_0);
    pressrelease(device, '1', KEY_1);
    pressrelease(device, '2', KEY_2);
    pressrelease(device, '3', KEY_3);
    pressrelease(device, '4', KEY_4);
    pressrelease(device, '5', KEY_5);
    pressrelease(device, '6', KEY_6);
    pressrelease(device, '7', KEY_7);
    pressrelease(device, '8', KEY_8);
    pressrelease(device, '9', KEY_9);

    pressrelease(device, '.', KEY_DOT);
    pressrelease(device, '+', KEY_EQUAL);
    pressrelease(device, '-', KEY_SLASH);
    pressrelease(device, ')', KEY_DOWN);
    pressrelease(device, '?', KEY_ENTER);
  }

  if(args->key_point_given)
    setkeysequence(device, '.', args->key_point_arg);
  if(args->key_plus_given)
    setkeysequence(device, '+', args->key_plus_arg);
  if(args->key_minus_given)
    setkeysequence(device, '-', args->key_minus_arg);
  if(args->key_before_given)
    setkeysequence(device, '(', args->key_before_arg);
  if(args->key_after_given)
    setkeysequence(device, ')', args->key_after_arg);
  if(args->key_off_given)
    setkeysequence(device, '?', args->key_off_arg);

  if(verbose)
    printmapping(device);
    
  if(uinput_register(device))
  {
    printf("Cannot open uinput device\n");
    return -1;
  }

#if 1
  if(input_register(device))
  {
    printf("Cannot open source input device\n");
    return -1;
  }
#endif

  if(pcspeaker_register(device))
  {
    printf("Cannot open pc speaker device\n");
  }
  
  if(verbose)
    printf("User space (uinput) converter for automatic input from digital measurement devices.\n");
  /* Create 1 independant thread
  ** normal remete events (kays)
  */

  if( (rc[THREAD_INPUT] = pthread_create( &thread[THREAD_INPUT], NULL, input_handler, (void *) (device) )) )
    printf("Thread creation failed: %d\n", rc[THREAD_INPUT]);

  /* graceful exit handler */
  signal(SIGINT, &terminate);
  signal(SIGTERM, &terminate);

  /* timer handler (to synthesize cursor keys release events) */
  memset(&sa, 0, sizeof (sa));    /* Install timer_handler   */
  sa.sa_handler = &timer_handler;
  sigaction(SIGALRM, &sa, NULL);

  /* Wait till threads are complete before main continues. Unless we  */
  /* wait we run the risk of executing an exit which will terminate   */
  /* the process and all threads before the threads have completed.   */

  for(i = 0; i < THREAD_MAX; i++)
    if(rc[i] == 0 || i == THREAD_INPUT)
      pthread_join(thread[i], NULL);

  pcspeaker_unregister(device);
  input_unregister(device);
  uinput_unregister(device);
  if(verbose)
    printf("exit.\n");
  
  return 0;
}
