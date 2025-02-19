export interface System {
  lang: any;
  plugin: { exec(key: string): void };

  control: any;
  openDialogFromTemplate(config: {
    id: string;
    options: unknown;
    datas?: unknown;
    type?: number;
    source?: unknown;
  }): void;
}
